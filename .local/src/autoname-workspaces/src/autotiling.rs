//! Event-driven aspect-ratio tiling for i3, sharing the workspace daemon's
//! native IPC implementation and avoiding the Python autotiling process.

use std::collections::VecDeque;
use std::io::Read;
use std::time::Duration;

use serde_json::Value;

use crate::ipc::{
    event_change, get_i3_socket_path, is_stream_disconnect, subscribe_events_with_payload,
    wait_for_i3_socket_after_failure, I3Client,
};

const WINDOW_EVENT: u32 = 0x8000_0003;
const MODE_EVENT: u32 = 0x8000_0002;
const EVENT_SUBSCRIPTION: &str = r#"["window", "mode"]"#;

pub fn run() {
    let mut socket_path = get_i3_socket_path();
    if socket_path.is_empty() {
        eprintln!("autotiling: i3 socket path not found; is i3 running?");
        std::process::exit(1);
    }

    let mut client = I3Client::new(socket_path.clone());
    let mut retry_delay = Duration::from_millis(50);
    loop {
        let mut events = match subscribe_events_with_payload(&socket_path, EVENT_SUBSCRIPTION) {
            Ok(stream) => stream,
            Err(error) => {
                eprintln!("autotiling: i3 event subscription failed: {error}");
                socket_path = wait_for_i3_socket_after_failure(&socket_path, &mut retry_delay);
                client = I3Client::new(socket_path.clone());
                continue;
            }
        };

        let mut body = Vec::new();
        loop {
            let mut header = [0u8; 14];
            if let Err(error) = events.read_exact(&mut header) {
                if !is_stream_disconnect(&error) {
                    eprintln!("autotiling: could not read i3 event header: {error}");
                }
                break;
            }

            let body_len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
            let event_type = u32::from_ne_bytes(header[10..14].try_into().unwrap());
            body.resize(body_len, 0);
            if let Err(error) = events.read_exact(&mut body) {
                if !is_stream_disconnect(&error) {
                    eprintln!("autotiling: could not read i3 event: {error}");
                }
                break;
            }

            retry_delay = Duration::from_millis(50);
            if event_requires_autotile(event_type, &body) {
                if let Err(error) = autotile_focused(&mut client) {
                    eprintln!("autotiling: failed to apply layout: {error}");
                }
            }
        }

        socket_path = wait_for_i3_socket_after_failure(&socket_path, &mut retry_delay);
        client = I3Client::new(socket_path.clone());
    }
}

fn event_requires_autotile(event_type: u32, body: &[u8]) -> bool {
    if event_type == MODE_EVENT {
        return true;
    }
    if event_type != WINDOW_EVENT {
        return false;
    }

    let Some(change) = event_change(body) else {
        return true;
    };

    !matches!(change, "title" | "urgent" | "mark")
}

fn autotile_focused(client: &mut I3Client) -> std::io::Result<()> {
    let tree = client.get_tree()?;
    let Some((focused, parent)) = find_focused(&tree) else {
        return Ok(());
    };

    let parent_layout = parent.get("layout").and_then(Value::as_str).unwrap_or("");
    let Some(wanted_layout) = desired_layout(focused, parent) else {
        return Ok(());
    };

    if parent_layout != wanted_layout {
        client.run_command(wanted_layout)?;
    }
    Ok(())
}

fn find_focused(root: &Value) -> Option<(&Value, &Value)> {
    let mut pending = VecDeque::new();
    for key in ["nodes", "floating_nodes"] {
        if let Some(children) = root.get(key).and_then(Value::as_array) {
            pending.extend(children.iter().map(|child| (child, root)));
        }
    }

    while let Some((node, parent)) = pending.pop_front() {
        if node.get("focused").and_then(Value::as_bool) == Some(true) {
            return Some((node, parent));
        }
        for key in ["nodes", "floating_nodes"] {
            if let Some(children) = node.get(key).and_then(Value::as_array) {
                pending.extend(children.iter().map(|child| (child, node)));
            }
        }
    }
    None
}

fn desired_layout(focused: &Value, parent: &Value) -> Option<&'static str> {
    let floating = focused
        .get("floating")
        .and_then(Value::as_str)
        .is_some_and(|state| state.contains("_on"));
    let parent_layout = parent.get("layout").and_then(Value::as_str).unwrap_or("");
    let fullscreen = focused
        .get("fullscreen_mode")
        .and_then(Value::as_u64)
        .unwrap_or(0)
        != 0;
    if floating || fullscreen || matches!(parent_layout, "stacked" | "tabbed") {
        return None;
    }

    let rect = focused.get("rect")?;
    let width = rect.get("width")?.as_u64()?;
    let height = rect.get("height")?.as_u64()?;
    Some(if height > width { "splitv" } else { "splith" })
}

#[cfg(test)]
mod tests {
    use super::{desired_layout, find_focused};
    use serde_json::json;

    #[test]
    fn chooses_aspect_ratio_and_skips_non_tiling_modes() {
        let parent = json!({"layout":"splith"});
        let tall = json!({
            "floating":"auto_off", "fullscreen_mode":0,
            "rect":{"width":700,"height":701}
        });
        let wide = json!({
            "floating":"user_off", "fullscreen_mode":0,
            "rect":{"width":701,"height":700}
        });
        assert_eq!(desired_layout(&tall, &parent), Some("splitv"));
        assert_eq!(desired_layout(&wide, &parent), Some("splith"));

        let floating = json!({
            "floating":"user_on", "fullscreen_mode":0,
            "rect":{"width":700,"height":701}
        });
        let fullscreen = json!({
            "floating":"auto_off", "fullscreen_mode":1,
            "rect":{"width":700,"height":701}
        });
        assert_eq!(desired_layout(&floating, &parent), None);
        assert_eq!(desired_layout(&fullscreen, &parent), None);
        assert_eq!(desired_layout(&tall, &json!({"layout":"tabbed"})), None);
        assert_eq!(desired_layout(&tall, &json!({"layout":"stacked"})), None);
    }

    #[test]
    fn focused_lookup_matches_i3ipc_breadth_first_order() {
        let tree = json!({"name":"root","nodes":[
            {"name":"outer","nodes":[{"name":"deep-focus","focused":true}]},
            {"name":"shallow-focus","focused":true}
        ]});
        let (focused, parent) = find_focused(&tree).unwrap();
        assert_eq!(focused["name"], "shallow-focus");
        assert_eq!(parent["name"], "root");
    }
}
