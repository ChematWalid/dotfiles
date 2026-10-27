//! Layout and workspace status inspector for i3.
//! Inspects active workspace, focused container/leaf layout, and autotiling daemon status.

use std::io;
use std::process::Command;

use serde::{Deserialize, Serialize};

use crate::ipc::I3Connection;
use crate::tree::{
    build_container_path, get_active_leaf, get_active_output, get_visible_workspace_for_output,
    I3Node,
};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LayoutStatus {
    pub workspace_name: String,
    pub workspace_num: Option<i32>,
    pub output: String,
    pub focused_window_id: Option<i64>,
    pub focused_window_class: Option<String>,
    pub focused_window_title: Option<String>,
    pub container_layout: String,
    pub is_floating: bool,
    pub is_fullscreen: bool,
    pub autotiling_active: bool,
}

pub fn check_autotiling_active() -> bool {
    // Check systemd user service first
    if let Ok(status) = Command::new("systemctl")
        .args(["--user", "is-active", "--quiet", "autotiling.service"])
        .status()
    {
        if status.success() {
            return true;
        }
    }
    // Fallback: check if autotiling process is running
    if let Ok(status) = Command::new("pgrep")
        .args(["-x", "autotiling"])
        .status()
    {
        if status.success() {
            return true;
        }
    }
    false
}

pub fn inspect_status(tree: &I3Node, autotiling_active: bool) -> LayoutStatus {
    let focused = tree.find_focused();
    let leaf = get_active_leaf(tree, focused);

    // Identify output
    let output_node = get_active_output(tree, focused);
    let output_name = output_node
        .and_then(|o| o.name.clone())
        .unwrap_or_else(|| "Unknown".to_string());

    // Identify active workspace and container path
    let (
        ws_name,
        ws_num,
        container_layout,
        is_floating,
        is_fullscreen,
        win_id,
        win_class,
        win_title,
    ) = if let Some(l) = leaf {
        let path = build_container_path(tree, l.id);
        let ws = path
            .last()
            .copied()
            .or_else(|| output_node.and_then(get_visible_workspace_for_output));

        let ws_name = ws
            .and_then(|w| w.name.clone())
            .unwrap_or_else(|| "Unknown".to_string());
        let ws_num = ws.and_then(|w| w.num);

        let is_client_window = l.node_type != "workspace"
            && l.node_type != "root"
            && l.node_type != "output"
            && l.node_type != "dockarea"
            && l.name.as_deref() != Some("content");

        // Container layout:
        // If client window with parent container (path.len() >= 2), path[1] is parent.
        // Otherwise, workspace layout.
        let layout = if is_client_window && path.len() >= 2 {
            path[1].layout.clone()
        } else if let Some(w) = ws {
            w.layout.clone()
        } else {
            l.layout.clone()
        };

        let floating = is_client_window
            && (l.floating.as_deref().is_some_and(|f| f != "no")
                || path
                    .iter()
                    .any(|n| n.floating.as_deref().is_some_and(|f| f != "no")));

        let fullscreen = is_client_window && l.fullscreen_mode != 0;

        let (wid, wclass, wtitle) = if is_client_window {
            let wid = Some(l.id);
            let wclass = l
                .window_properties
                .as_ref()
                .and_then(|p| p.window_class.clone());
            let wtitle = l
                .window_properties
                .as_ref()
                .and_then(|p| p.title.clone())
                .or_else(|| l.name.clone());
            (wid, wclass, wtitle)
        } else {
            (None, None, None)
        };

        (
            ws_name,
            ws_num,
            layout,
            floating,
            fullscreen,
            wid,
            wclass,
            wtitle,
        )
    } else {
        let ws = output_node
            .and_then(get_visible_workspace_for_output)
            .or_else(|| tree.workspaces().iter().find(|w| w.focused).copied())
            .or_else(|| tree.workspaces().first().copied());

        let ws_name = ws
            .and_then(|w| w.name.clone())
            .unwrap_or_else(|| "Unknown".to_string());
        let ws_num = ws.and_then(|w| w.num);
        let layout = ws
            .map(|w| w.layout.clone())
            .unwrap_or_else(|| "none".to_string());

        (ws_name, ws_num, layout, false, false, None, None, None)
    };

    LayoutStatus {
        workspace_name: ws_name,
        workspace_num: ws_num,
        output: output_name,
        focused_window_id: win_id,
        focused_window_class: win_class,
        focused_window_title: win_title,
        container_layout,
        is_floating,
        is_fullscreen,
        autotiling_active,
    }
}

pub fn run_status(json_output: bool) -> io::Result<()> {
    let mut i3 = I3Connection::connect()?;
    let tree = i3.get_tree()?;
    let autotiling_active = check_autotiling_active();

    let status = inspect_status(&tree, autotiling_active);

    let stdout = io::stdout();
    let mut handle = stdout.lock();
    use io::Write;

    if json_output {
        let json_str = serde_json::to_string_pretty(&status)
            .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
        if let Err(e) = writeln!(handle, "{json_str}") {
            if e.kind() == io::ErrorKind::BrokenPipe {
                return Ok(());
            }
            return Err(e);
        }
    } else {
        let lines = [
            format!(
                "Workspace:   {} (output: {})",
                status.workspace_name, status.output
            ),
            if let Some(id) = status.focused_window_id {
                let class = status.focused_window_class.as_deref().unwrap_or("Unknown");
                let title = status.focused_window_title.as_deref().unwrap_or("Unknown");
                format!("Focused:     {class} [id: {id}] (\"{title}\")")
            } else {
                "Focused:     none (empty workspace)".to_string()
            },
            format!("Layout:      {}", status.container_layout),
            format!(
                "Floating:    {}",
                if status.is_floating { "yes" } else { "no" }
            ),
            format!(
                "Fullscreen:  {}",
                if status.is_fullscreen { "yes" } else { "no" }
            ),
            format!(
                "Autotiling:  {}",
                if status.autotiling_active {
                    "active"
                } else {
                    "inactive"
                }
            ),
        ];

        for line in lines {
            if let Err(e) = writeln!(handle, "{line}") {
                if e.kind() == io::ErrorKind::BrokenPipe {
                    return Ok(());
                }
                return Err(e);
            }
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::tree::WindowProperties;

    fn make_node(
        id: i64,
        node_type: &str,
        layout: &str,
        focused: bool,
        nodes: Vec<I3Node>,
    ) -> I3Node {
        I3Node {
            id,
            name: Some(format!("{node_type}-{id}")),
            node_type: node_type.to_string(),
            layout: layout.to_string(),
            focused,
            focus: nodes.iter().map(|n| n.id).collect(),
            nodes,
            floating_nodes: Vec::new(),
            floating: None,
            fullscreen_mode: 0,
            num: None,
            window: None,
            window_properties: None,
        }
    }

    #[test]
    fn test_status_with_focused_window() {
        let mut leaf = make_node(100, "con", "none", true, vec![]);
        leaf.window_properties = Some(WindowProperties {
            window_class: Some("Alacritty".into()),
            instance: Some("alacritty".into()),
            title: Some("Terminal".into()),
        });

        let mut ws = make_node(10, "workspace", "splith", false, vec![leaf]);
        ws.name = Some("1: Web".into());
        ws.num = Some(1);

        let mut output = make_node(2, "output", "none", false, vec![ws]);
        output.name = Some("DP-1".into());

        let root = make_node(1, "root", "none", false, vec![output]);

        let status = inspect_status(&root, true);
        assert_eq!(status.workspace_name, "1: Web");
        assert_eq!(status.workspace_num, Some(1));
        assert_eq!(status.output, "DP-1");
        assert_eq!(status.container_layout, "splith");
        assert_eq!(status.focused_window_id, Some(100));
        assert_eq!(status.focused_window_class.as_deref(), Some("Alacritty"));
        assert_eq!(status.focused_window_title.as_deref(), Some("Terminal"));
        assert!(!status.is_floating);
        assert!(!status.is_fullscreen);
        assert!(status.autotiling_active);
    }

    #[test]
    fn test_status_tabbed_container() {
        let leaf1 = make_node(101, "con", "none", false, vec![]);
        let leaf2 = make_node(102, "con", "none", true, vec![]);

        let tab_con = make_node(20, "con", "tabbed", false, vec![leaf1, leaf2]);
        let mut ws = make_node(10, "workspace", "splith", false, vec![tab_con]);
        ws.name = Some("2: Code".into());
        ws.num = Some(2);

        let mut output = make_node(2, "output", "none", false, vec![ws]);
        output.name = Some("HDMI-1".into());

        let root = make_node(1, "root", "none", false, vec![output]);

        let status = inspect_status(&root, false);
        assert_eq!(status.workspace_name, "2: Code");
        assert_eq!(status.output, "HDMI-1");
        assert_eq!(status.container_layout, "tabbed");
        assert_eq!(status.focused_window_id, Some(102));
        assert!(!status.autotiling_active);
    }

    #[test]
    fn test_status_floating_window() {
        let mut leaf = make_node(103, "con", "none", true, vec![]);
        leaf.floating = Some("user_on".into());

        let mut ws = make_node(10, "workspace", "splith", false, vec![leaf]);
        ws.name = Some("3: Misc".into());

        let mut output = make_node(2, "output", "none", false, vec![ws]);
        output.name = Some("eDP-1".into());

        let root = make_node(1, "root", "none", false, vec![output]);

        let status = inspect_status(&root, true);
        assert!(status.is_floating);
    }

    #[test]
    fn test_status_empty_workspace() {
        let mut ws = make_node(10, "workspace", "splith", true, vec![]);
        ws.name = Some("4: Empty".into());
        ws.num = Some(4);

        let mut output = make_node(2, "output", "none", false, vec![ws]);
        output.name = Some("DP-2".into());

        let root = make_node(1, "root", "none", false, vec![output]);

        let status = inspect_status(&root, false);
        assert_eq!(status.workspace_name, "4: Empty");
        assert_eq!(status.workspace_num, Some(4));
        assert_eq!(status.output, "DP-2");
        assert_eq!(status.focused_window_id, None);
        assert_eq!(status.focused_window_class, None);
    }

    #[test]
    fn test_status_json_serialization() {
        let status = LayoutStatus {
            workspace_name: "1: Dev".into(),
            workspace_num: Some(1),
            output: "DP-1".into(),
            focused_window_id: Some(42),
            focused_window_class: Some("Code".into()),
            focused_window_title: Some("main.rs".into()),
            container_layout: "splitv".into(),
            is_floating: false,
            is_fullscreen: false,
            autotiling_active: true,
        };

        let json = serde_json::to_string(&status).expect("serialization failed");
        assert!(json.contains("\"workspace_name\":\"1: Dev\""));
        assert!(json.contains("\"container_layout\":\"splitv\""));
        assert!(json.contains("\"autotiling_active\":true"));

        let deserialized: LayoutStatus =
            serde_json::from_str(&json).expect("deserialization failed");
        assert_eq!(deserialized, status);
    }
}
