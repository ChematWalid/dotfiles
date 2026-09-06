//! Workspace tree traversal and renaming logic.

use crate::icons::{get_icon, is_ignored};
use crate::ipc::I3Client;
use regex::Regex;
use serde_json::Value;

pub fn get_workspace_number(name: &str, re: &Regex) -> String {
    if let Some(caps) = re.captures(name) {
        if let Some(m) = caps.get(1) {
            return m.as_str().to_string();
        }
    }
    name.to_string()
}

pub fn find_workspaces(node: &Value, out: &mut Vec<Value>) {
    if node.get("type").and_then(|t| t.as_str()) == Some("workspace") {
        if let Some(name) = node.get("name").and_then(|n| n.as_str()) {
            if !name.starts_with("__") {
                out.push(node.clone());
            }
        }
        return;
    }
    if let Some(nodes) = node.get("nodes").and_then(|n| n.as_array()) {
        for n in nodes {
            find_workspaces(n, out);
        }
    }
    if let Some(floating) = node.get("floating_nodes").and_then(|n| n.as_array()) {
        for n in floating {
            find_workspaces(n, out);
        }
    }
}

pub fn find_leaves(node: &Value, leaves: &mut Vec<Value>) {
    let empty_vec = Vec::new();
    let nodes = node
        .get("nodes")
        .and_then(|n| n.as_array())
        .unwrap_or(&empty_vec);
    let floating = node
        .get("floating_nodes")
        .and_then(|n| n.as_array())
        .unwrap_or(&empty_vec);

    if nodes.is_empty() && floating.is_empty() {
        if node.get("window").is_some() || node.get("name").is_some() {
            leaves.push(node.clone());
        }
    } else {
        for n in nodes {
            find_leaves(n, leaves);
        }
        for n in floating {
            find_leaves(n, leaves);
        }
    }
}

pub fn update_workspaces(client: &mut I3Client, re_ws: &Regex) {
    let tree = match client.get_tree() {
        Ok(t) => t,
        Err(_) => return,
    };

    let mut workspaces = Vec::new();
    find_workspaces(&tree, &mut workspaces);

    for ws in workspaces {
        let ws_name = match ws.get("name").and_then(|n| n.as_str()) {
            Some(n) => n,
            None => continue,
        };

        let ws_num = get_workspace_number(ws_name, re_ws);
        let mut leaves = Vec::new();
        find_leaves(&ws, &mut leaves);

        let mut icons: Vec<&str> = Vec::new();
        for w in leaves {
            let name = w.get("name").and_then(|n| n.as_str()).unwrap_or("");
            let (cls, inst) = if let Some(props) = w.get("window_properties") {
                (
                    props.get("class").and_then(|c| c.as_str()).unwrap_or(""),
                    props.get("instance").and_then(|i| i.as_str()).unwrap_or(""),
                )
            } else {
                ("", "")
            };

            if (w.get("window").is_some() || !name.is_empty()) && !is_ignored(cls, inst, name) {
                let icon = get_icon(cls, inst, name);
                if !icons.contains(&icon) {
                    icons.push(icon);
                }
            }
        }

        let new_name = if !icons.is_empty() {
            format!("{} {}", ws_num, icons.join(" "))
        } else {
            ws_num
        };

        if ws_name != new_name {
            let cmd = format!("rename workspace \"{}\" to \"{}\"", ws_name, new_name);
            let _ = client.run_command(&cmd);
        }
    }
}
