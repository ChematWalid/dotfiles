//! Representation and navigation algorithms for the i3 container tree.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct I3Node {
    pub id: i64,
    #[serde(default)]
    pub name: Option<String>,
    #[serde(rename = "type", default)]
    pub node_type: String,
    #[serde(default)]
    pub layout: String,
    #[serde(default)]
    pub focused: bool,
    #[serde(default)]
    pub focus: Vec<i64>,
    #[serde(default)]
    pub nodes: Vec<I3Node>,
    #[serde(default)]
    pub floating_nodes: Vec<I3Node>,
    #[serde(default)]
    pub floating: Option<String>,
    #[serde(default)]
    pub fullscreen_mode: i32,
}

impl I3Node {
    /// Recursively searches for the currently focused container node in the tree.
    pub fn find_focused(&self) -> Option<&I3Node> {
        if self.focused {
            return Some(self);
        }
        for child in &self.nodes {
            if let Some(f) = child.find_focused() {
                return Some(f);
            }
        }
        for child in &self.floating_nodes {
            if let Some(f) = child.find_focused() {
                return Some(f);
            }
        }
        None
    }

    /// Collects all non-internal workspace nodes in the tree.
    pub fn workspaces(&self) -> Vec<&I3Node> {
        let mut list = Vec::new();
        self.collect_workspaces(&mut list);
        list
    }

    fn collect_workspaces<'a>(&'a self, list: &mut Vec<&'a I3Node>) {
        if self.node_type == "workspace" && !self.name.as_deref().unwrap_or("").starts_with("__") {
            list.push(self);
            return;
        }
        for child in &self.nodes {
            child.collect_workspaces(list);
        }
        for child in &self.floating_nodes {
            child.collect_workspaces(list);
        }
    }

    /// Recursively searches for a node with the given ID.
    pub fn find_node_by_id(&self, target_id: i64) -> Option<&I3Node> {
        if self.id == target_id {
            return Some(self);
        }
        for child in &self.nodes {
            if let Some(n) = child.find_node_by_id(target_id) {
                return Some(n);
            }
        }
        for child in &self.floating_nodes {
            if let Some(n) = child.find_node_by_id(target_id) {
                return Some(n);
            }
        }
        None
    }
}

/// Recursively descends a container following most-recently-used focus order
/// (con.focus[0]) to find the true active leaf window.
pub fn find_mru_leaf(con: &I3Node) -> &I3Node {
    let mut curr = con;
    while !curr.nodes.is_empty() {
        if let Some(&child_id) = curr.focus.first() {
            if let Some(found) = curr.nodes.iter().find(|n| n.id == child_id) {
                curr = found;
                continue;
            }
        }
        curr = &curr.nodes[0];
    }
    curr
}

/// Finds the active/visible workspace for a given output node.
/// Handles both i3 layout (output -> content -> workspace) and Sway layout (output -> workspace).
pub fn get_visible_workspace_for_output(output: &I3Node) -> Option<&I3Node> {
    // 1. i3 style: check for a child container named "content"
    if let Some(content) = output
        .nodes
        .iter()
        .find(|n| n.name.as_deref() == Some("content"))
    {
        // Follow content.focus order to find the MRU/visible workspace
        for &ws_id in &content.focus {
            if let Some(ws) = content
                .nodes
                .iter()
                .find(|n| n.id == ws_id && n.node_type == "workspace")
            {
                if !ws.name.as_deref().unwrap_or("").starts_with("__") {
                    return Some(ws);
                }
            }
        }
        // Fallback: first non-internal workspace in content
        if let Some(ws) = content.nodes.iter().find(|n| {
            n.node_type == "workspace" && !n.name.as_deref().unwrap_or("").starts_with("__")
        }) {
            return Some(ws);
        }
    }

    // 2. Sway style: workspaces are direct children of output
    for &ws_id in &output.focus {
        if let Some(ws) = output
            .nodes
            .iter()
            .find(|n| n.id == ws_id && n.node_type == "workspace")
        {
            if !ws.name.as_deref().unwrap_or("").starts_with("__") {
                return Some(ws);
            }
        }
    }

    // Fallback: first non-internal workspace directly in output.nodes
    output
        .nodes
        .iter()
        .find(|n| n.node_type == "workspace" && !n.name.as_deref().unwrap_or("").starts_with("__"))
}

/// Finds the active physical output from the root tree.
/// Considers focused output or MRU focus order from root.
pub fn get_active_output<'a>(tree: &'a I3Node, focused: Option<&'a I3Node>) -> Option<&'a I3Node> {
    // If focused is itself an output (and not __i3)
    if let Some(f) = focused {
        if f.node_type == "output" && f.name.as_deref() != Some("__i3") {
            return Some(f);
        }
    }

    // If focused is inside a specific output (e.g. dockarea or content)
    if let Some(f) = focused {
        for output in &tree.nodes {
            if output.node_type == "output"
                && output.name.as_deref() != Some("__i3")
                && (output.id == f.id || output.find_node_by_id(f.id).is_some())
            {
                return Some(output);
            }
        }
    }

    // Follow root.focus order to find the active physical output
    for &out_id in &tree.focus {
        if let Some(out) = tree
            .nodes
            .iter()
            .find(|n| n.id == out_id && n.node_type == "output")
        {
            if out.name.as_deref() != Some("__i3") {
                return Some(out);
            }
        }
    }

    // Fallback: first physical output in tree.nodes
    tree.nodes
        .iter()
        .find(|n| n.node_type == "output" && n.name.as_deref() != Some("__i3"))
}

/// Ensures we have an active leaf window.
/// If focus is at root, output, dockarea, content, workspace, or intermediate container level,
/// recovers the active leaf on the visible workspace using MRU focus order.
pub fn get_active_leaf<'a>(tree: &'a I3Node, focused: Option<&'a I3Node>) -> Option<&'a I3Node> {
    if let Some(f) = focused {
        // Check if f is directly a workspace
        if f.node_type == "workspace" {
            return Some(find_mru_leaf(f));
        }

        // Check if f is inside a workspace
        let path = build_container_path(tree, f.id);
        let is_in_workspace = path.last().is_some_and(|n| n.node_type == "workspace");

        if is_in_workspace {
            // If f has child nodes, it's an intermediate container: descend to MRU leaf
            if !f.nodes.is_empty() {
                return Some(find_mru_leaf(f));
            }
            // f is a normal leaf window inside the workspace
            return Some(f);
        }
    }

    // Focus escaped outside workspace (root, output, dockarea, content) or was None
    let output = get_active_output(tree, focused);
    let ws = output
        .and_then(get_visible_workspace_for_output)
        .or_else(|| {
            let all_ws = tree.workspaces();
            all_ws
                .iter()
                .find(|w| w.focused)
                .copied()
                .or_else(|| all_ws.first().copied())
        })?;

    Some(find_mru_leaf(ws))
}

fn find_path_to_leaf<'a>(current: &'a I3Node, leaf_id: i64, path: &mut Vec<&'a I3Node>) -> bool {
    if current.id == leaf_id {
        path.push(current);
        return true;
    }
    for child in &current.nodes {
        if find_path_to_leaf(child, leaf_id, path) {
            path.push(current);
            return true;
        }
    }
    for child in &current.floating_nodes {
        if find_path_to_leaf(child, leaf_id, path) {
            path.push(current);
            return true;
        }
    }
    false
}

/// Builds the path from the leaf window up to the workspace.
/// path[0] is the leaf window.
/// path[last] is the workspace.
pub fn build_container_path(tree: &I3Node, leaf_id: i64) -> Vec<&I3Node> {
    let mut full_path = Vec::new();
    if !find_path_to_leaf(tree, leaf_id, &mut full_path) {
        return Vec::new();
    }
    if let Some(ws_pos) = full_path.iter().position(|n| n.node_type == "workspace") {
        full_path.truncate(ws_pos + 1);
    }
    full_path
}

/// Returns eligible grouping containers in path[1..] (from innermost to outermost).
/// Excludes autotiling single-child wrappers where sibling windows exist in parent,
/// while preserving single-window workspace containers to prevent redundant nesting.
pub fn get_eligible_grouping_containers<'a>(path: &[&'a I3Node]) -> Vec<&'a I3Node> {
    if path.len() <= 1 {
        return Vec::new();
    }

    if path.len() == 2 {
        // [leaf, workspace]
        return vec![path[1]];
    }

    let ws = path[path.len() - 1];
    let mut eligible = Vec::new();

    for idx in 1..path.len() {
        let con = path[idx];
        if con.node_type == "workspace" {
            if con.nodes.len() > 1 || eligible.is_empty() {
                eligible.push(con);
            }
        } else if con.nodes.len() > 1
            || con.layout == "tabbed"
            || con.layout == "stacked"
            || (idx == path.len() - 2 && ws.nodes.len() == 1)
        {
            eligible.push(con);
        }
    }

    if eligible.is_empty() {
        eligible.push(path[1]);
    }

    eligible
}

#[cfg(test)]
mod tests {
    use super::*;

    fn node(
        id: i64,
        node_type: &str,
        layout: &str,
        focused: bool,
        focus: Vec<i64>,
        nodes: Vec<I3Node>,
    ) -> I3Node {
        I3Node {
            id,
            name: Some(format!("{node_type}-{id}")),
            node_type: node_type.to_string(),
            layout: layout.to_string(),
            focused,
            focus,
            nodes,
            floating_nodes: Vec::new(),
            floating: None,
            fullscreen_mode: 0,
        }
    }

    #[test]
    fn test_find_focused_and_workspaces() {
        let leaf1 = node(101, "con", "none", false, vec![], vec![]);
        let leaf2 = node(102, "con", "none", true, vec![], vec![]);
        let ws1 = node(
            10,
            "workspace",
            "splith",
            false,
            vec![102, 101],
            vec![leaf1, leaf2],
        );
        let root = node(1, "root", "splith", false, vec![10], vec![ws1]);

        let focused = root.find_focused();
        assert!(focused.is_some());
        assert_eq!(focused.unwrap().id, 102);

        let ws_list = root.workspaces();
        assert_eq!(ws_list.len(), 1);
        assert_eq!(ws_list[0].id, 10);
    }

    #[test]
    fn test_find_mru_leaf() {
        let leaf1 = node(101, "con", "none", false, vec![], vec![]);
        let leaf2 = node(102, "con", "none", false, vec![], vec![]);
        let con = node(
            20,
            "con",
            "splith",
            false,
            vec![102, 101],
            vec![leaf1, leaf2],
        );
        let ws = node(1, "workspace", "splith", false, vec![20], vec![con]);

        let mru = find_mru_leaf(&ws);
        assert_eq!(mru.id, 102);
    }

    #[test]
    fn test_get_active_leaf_at_different_levels() {
        let leaf1 = node(101, "con", "none", false, vec![], vec![]);
        let leaf2 = node(102, "con", "none", false, vec![], vec![]);
        let con = node(
            20,
            "con",
            "splith",
            true,
            vec![102, 101],
            vec![leaf1, leaf2],
        );
        let ws = node(10, "workspace", "splith", false, vec![20], vec![con]);
        let root = node(1, "root", "splith", false, vec![10], vec![ws]);

        // When focused at container level (con id 20)
        let active = get_active_leaf(&root, Some(&root.nodes[0].nodes[0]));
        assert_eq!(active.unwrap().id, 102);

        // When focused directly at leaf
        let active_leaf = get_active_leaf(&root, Some(&root.nodes[0].nodes[0].nodes[0]));
        assert_eq!(active_leaf.unwrap().id, 101);

        // When focused at root level
        let active_root = get_active_leaf(&root, Some(&root));
        assert_eq!(active_root.unwrap().id, 102);
    }

    #[test]
    fn test_build_container_path() {
        let leaf = node(101, "con", "none", true, vec![], vec![]);
        let inner = node(20, "con", "splitv", false, vec![101], vec![leaf]);
        let ws = node(10, "workspace", "splith", false, vec![20], vec![inner]);
        let content = node(5, "con", "splith", false, vec![10], vec![ws]);
        let mut content_named = content;
        content_named.name = Some("content".into());
        let root = node(1, "root", "splith", false, vec![5], vec![content_named]);

        let path = build_container_path(&root, 101);
        assert_eq!(path.len(), 3);
        assert_eq!(path[0].id, 101); // leaf
        assert_eq!(path[1].id, 20); // inner con
        assert_eq!(path[2].id, 10); // workspace
    }

    #[test]
    fn test_get_eligible_grouping_containers_autotiling() {
        // Workspace with 2 windows autotiled:
        // ws (nodes: [inner, leaf2])
        // inner (nodes: [leaf1])
        let leaf1 = node(101, "con", "none", true, vec![], vec![]);
        let leaf2 = node(102, "con", "none", false, vec![], vec![]);
        let inner = node(20, "con", "splitv", false, vec![101], vec![leaf1]);
        let ws = node(
            10,
            "workspace",
            "splith",
            false,
            vec![20, 102],
            vec![inner, leaf2],
        );
        let root = node(1, "root", "splith", false, vec![10], vec![ws]);

        let path = build_container_path(&root, 101);
        let eligible = get_eligible_grouping_containers(&path);

        // inner (20) has only 1 node and is not tabbed/stacked, and ws has 2 nodes.
        // So inner is not eligible; ws is the eligible grouping container!
        assert_eq!(eligible.len(), 1);
        assert_eq!(eligible[0].id, 10);
    }

    #[test]
    fn test_get_eligible_grouping_containers_single_window_ws() {
        // Workspace with 1 window wrapped in a container:
        // ws (nodes: [inner])
        // inner (nodes: [leaf1])
        let leaf1 = node(101, "con", "none", true, vec![], vec![]);
        let inner = node(20, "con", "splith", false, vec![101], vec![leaf1]);
        let ws = node(10, "workspace", "splith", false, vec![20], vec![inner]);
        let root = node(1, "root", "splith", false, vec![10], vec![ws]);

        let path = build_container_path(&root, 101);
        let eligible = get_eligible_grouping_containers(&path);

        // inner is sole container on single-window workspace, so it should be eligible
        assert_eq!(eligible.len(), 1);
        assert_eq!(eligible[0].id, 20);
    }

    #[test]
    fn test_multi_monitor_output_and_active_workspace_recovery() {
        // Output 1 (DP-1): Workspace 1 (id 10) -> leaf1 (id 101)
        let leaf1 = node(101, "con", "none", false, vec![], vec![]);
        let ws1 = node(10, "workspace", "splith", false, vec![101], vec![leaf1]);
        let mut content1 = node(2, "con", "splith", false, vec![10], vec![ws1]);
        content1.name = Some("content".into());
        let mut out1 = node(100, "output", "splith", false, vec![2], vec![content1]);
        out1.name = Some("DP-1".into());

        // Output 2 (HDMI-1): Workspace 5 (id 50) -> leaf5 (id 501)
        let leaf5 = node(501, "con", "none", false, vec![], vec![]);
        let ws5 = node(50, "workspace", "splith", false, vec![501], vec![leaf5]);
        let mut content2 = node(3, "con", "splith", false, vec![50], vec![ws5]);
        content2.name = Some("content".into());
        let mut out2 = node(200, "output", "splith", false, vec![3], vec![content2]);
        out2.name = Some("HDMI-1".into());

        // Root focus points to HDMI-1 (id 200) as MRU active monitor
        let root = node(1, "root", "splith", false, vec![200, 100], vec![out1, out2]);

        // When focus escaped to root, it must recover leaf5 from HDMI-1, NOT leaf1 from DP-1!
        let active = get_active_leaf(&root, Some(&root));
        assert!(active.is_some());
        assert_eq!(active.unwrap().id, 501);

        // When focused is None, it also recovers leaf5
        let active_none = get_active_leaf(&root, None);
        assert!(active_none.is_some());
        assert_eq!(active_none.unwrap().id, 501);
    }

    #[test]
    fn test_dockarea_focus_recovery() {
        let polybar = node(999, "con", "none", true, vec![], vec![]);
        let dock = node(
            99,
            "dockarea",
            "dockarea",
            false,
            vec![999],
            vec![polybar.clone()],
        );
        let leaf = node(101, "con", "none", false, vec![], vec![]);
        let ws = node(10, "workspace", "splith", false, vec![101], vec![leaf]);
        let mut content = node(5, "con", "splith", false, vec![10], vec![ws]);
        content.name = Some("content".into());
        let mut out = node(
            2,
            "output",
            "splith",
            false,
            vec![5, 99],
            vec![dock, content],
        );
        out.name = Some("DVI-I-1".into());
        let root = node(1, "root", "splith", false, vec![2], vec![out]);

        // When polybar in dockarea has focus, get_active_leaf recovers leaf 101 on the workspace
        let active = get_active_leaf(&root, Some(&polybar));
        assert!(active.is_some());
        assert_eq!(active.unwrap().id, 101);
    }

    #[test]
    fn test_sway_style_output_hierarchy() {
        // In Sway, workspaces are direct children of output without a content container
        let leaf = node(101, "con", "none", false, vec![], vec![]);
        let ws = node(10, "workspace", "splith", false, vec![101], vec![leaf]);
        let mut out = node(2, "output", "splith", false, vec![10], vec![ws]);
        out.name = Some("eDP-1".into());
        let root = node(1, "root", "splith", false, vec![2], vec![out]);

        let active = get_active_leaf(&root, Some(&root));
        assert!(active.is_some());
        assert_eq!(active.unwrap().id, 101);
    }
}
