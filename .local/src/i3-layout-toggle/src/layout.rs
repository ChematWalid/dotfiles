//! Layout switching decisions and command generation for i3.

use crate::tree::I3Node;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Action {
    Tab,
    Toggle,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum LayoutPlan {
    ExecuteCommand(String),
    FocusLeaf(i64),
    DirectLayout(&'static str),
    NoOp,
}

/// Builds the layout switching command string with focus guarantees and fullscreen preservation.
pub fn build_execute_command(
    child_id: i64,
    leaf_id: i64,
    layout_cmd: &str,
    was_fullscreen: bool,
    was_container_focused: bool,
) -> String {
    let mut cmd = if child_id == leaf_id && !was_container_focused {
        // Leaf is already focused in i3: apply directly without switching focus
        layout_cmd.to_string()
    } else {
        // Child is an intermediate container, or focus was at container level
        format!("[con_id={child_id}] focus; {layout_cmd}; [con_id={leaf_id}] focus")
    };

    if was_fullscreen {
        cmd.push_str(&format!("; [con_id={leaf_id}] fullscreen enable"));
    }

    cmd
}

/// Computes the exact layout operation to perform based on the active container hierarchy.
pub fn plan_layout(
    action: Action,
    focused: &I3Node,
    leaf: &I3Node,
    path: &[&I3Node],
    eligible: &[&I3Node],
    was_container_focused: bool,
) -> LayoutPlan {
    // Do not alter tiling layout on floating windows or containers
    if leaf.floating.as_deref().is_some_and(|s| s.contains("_on"))
        || path.iter().any(|c| c.node_type == "floating_con")
    {
        return LayoutPlan::NoOp;
    }

    // Empty workspace or workspace-level target without windows
    if leaf.node_type == "workspace" || path.len() < 2 || eligible.is_empty() {
        let cmd = match action {
            Action::Tab => "layout tabbed",
            Action::Toggle => "layout toggle split",
        };
        return LayoutPlan::DirectLayout(cmd);
    }

    let was_fullscreen = leaf.fullscreen_mode != 0;

    match action {
        Action::Tab => {
            let target = if was_container_focused && path.iter().any(|c| c.id == focused.id) {
                let f_idx = path.iter().position(|c| c.id == focused.id).unwrap();
                if focused.layout == "tabbed" || focused.layout == "stacked" {
                    // Container already tabbed: climb to next eligible container above that is NOT already tabbed
                    let higher: Vec<_> = eligible
                        .iter()
                        .copied()
                        .filter(|c| {
                            let c_idx = path.iter().position(|p| p.id == c.id).unwrap();
                            c_idx > f_idx && c.layout != "tabbed" && c.layout != "stacked"
                        })
                        .collect();
                    if let Some(&h) = higher.first() {
                        h
                    } else {
                        // All higher containers (and focused) are already tabbed: idempotent, guarantee focus
                        return if was_fullscreen {
                            LayoutPlan::ExecuteCommand(format!(
                                "[con_id={}] focus; [con_id={}] fullscreen enable",
                                leaf.id, leaf.id
                            ))
                        } else {
                            LayoutPlan::FocusLeaf(leaf.id)
                        };
                    }
                } else {
                    focused
                }
            } else {
                // Normal leaf focus: find innermost eligible container not already tabbed/stacked
                let untabbed: Vec<_> = eligible
                    .iter()
                    .copied()
                    .filter(|c| c.layout != "tabbed" && c.layout != "stacked")
                    .collect();
                if let Some(&t) = untabbed.first() {
                    t
                } else {
                    // All eligible containers already tabbed: idempotent, guarantee focus
                    return if was_fullscreen {
                        LayoutPlan::ExecuteCommand(format!(
                            "[con_id={}] focus; [con_id={}] fullscreen enable",
                            leaf.id, leaf.id
                        ))
                    } else {
                        LayoutPlan::FocusLeaf(leaf.id)
                    };
                }
            };

            let target_pos = path
                .iter()
                .position(|c| c.id == target.id)
                .unwrap_or(path.len() - 1);
            let child = if target_pos > 0 {
                path[target_pos - 1]
            } else {
                leaf
            };

            let cmd = build_execute_command(
                child.id,
                leaf.id,
                "layout tabbed",
                was_fullscreen,
                was_container_focused,
            );
            LayoutPlan::ExecuteCommand(cmd)
        }
        Action::Toggle => {
            let target = if was_container_focused && path.iter().any(|c| c.id == focused.id) {
                focused
            } else if let Some(&tabbed_con) = eligible
                .iter()
                .find(|c| c.layout == "tabbed" || c.layout == "stacked")
            {
                // Untab the innermost tabbed/stacked container
                tabbed_con
            } else {
                // None are tabbed: toggle split orientation (splith <-> splitv)
                eligible[0]
            };

            let target_pos = path
                .iter()
                .position(|c| c.id == target.id)
                .unwrap_or(path.len() - 1);
            let child = if target_pos > 0 {
                path[target_pos - 1]
            } else {
                leaf
            };

            let cmd = build_execute_command(
                child.id,
                leaf.id,
                "layout toggle split",
                was_fullscreen,
                was_container_focused,
            );
            LayoutPlan::ExecuteCommand(cmd)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn node(id: i64, node_type: &str, layout: &str, focused: bool, nodes: Vec<I3Node>) -> I3Node {
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
            window: None,
            window_properties: None,
        }
    }

    #[test]
    fn test_build_execute_command() {
        // Child == leaf, leaf focused
        let cmd = build_execute_command(101, 101, "layout tabbed", false, false);
        assert_eq!(cmd, "layout tabbed");

        // Child != leaf
        let cmd = build_execute_command(20, 101, "layout tabbed", false, false);
        assert_eq!(cmd, "[con_id=20] focus; layout tabbed; [con_id=101] focus");

        // With fullscreen preservation
        let cmd = build_execute_command(20, 101, "layout tabbed", true, false);
        assert_eq!(
            cmd,
            "[con_id=20] focus; layout tabbed; [con_id=101] focus; [con_id=101] fullscreen enable"
        );

        // With was_container_focused
        let cmd = build_execute_command(101, 101, "layout tabbed", false, true);
        assert_eq!(cmd, "[con_id=101] focus; layout tabbed; [con_id=101] focus");
    }

    #[test]
    fn test_plan_layout_floating() {
        let mut leaf = node(101, "con", "none", true, vec![]);
        leaf.floating = Some("user_on".into());
        let ws = node(10, "workspace", "splith", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        let plan = plan_layout(Action::Tab, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::NoOp);
    }

    #[test]
    fn test_plan_layout_empty_ws() {
        let ws = node(10, "workspace", "splith", true, vec![]);
        let path = vec![&ws];
        let eligible = vec![];

        let plan = plan_layout(Action::Tab, &ws, &ws, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::DirectLayout("layout tabbed"));

        let plan = plan_layout(Action::Toggle, &ws, &ws, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::DirectLayout("layout toggle split"));
    }

    #[test]
    fn test_plan_layout_tab_normal_leaf() {
        let leaf = node(101, "con", "none", true, vec![]);
        let ws = node(10, "workspace", "splith", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        // Should switch ws to tabbed
        let plan = plan_layout(Action::Tab, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::ExecuteCommand("layout tabbed".into()));
    }

    #[test]
    fn test_plan_layout_tab_already_tabbed_idempotent() {
        let leaf = node(101, "con", "none", true, vec![]);
        let ws = node(10, "workspace", "tabbed", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        // Already tabbed: should focus leaf (idempotent)
        let plan = plan_layout(Action::Tab, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::FocusLeaf(101));
    }

    #[test]
    fn test_plan_layout_toggle_untab() {
        let leaf = node(101, "con", "none", true, vec![]);
        let ws = node(10, "workspace", "tabbed", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        // Tabbed: should untab via toggle split
        let plan = plan_layout(Action::Toggle, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(
            plan,
            LayoutPlan::ExecuteCommand("layout toggle split".into())
        );
    }

    #[test]
    fn test_plan_layout_toggle_split_orientation() {
        let leaf = node(101, "con", "none", true, vec![]);
        let ws = node(10, "workspace", "splith", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        // Not tabbed: should toggle split
        let plan = plan_layout(Action::Toggle, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(
            plan,
            LayoutPlan::ExecuteCommand("layout toggle split".into())
        );
    }

    #[test]
    fn test_plan_layout_floating_con_in_path() {
        let leaf = node(101, "con", "none", true, vec![]);
        let floating_wrapper = node(200, "floating_con", "splith", false, vec![leaf.clone()]);
        let ws = node(
            10,
            "workspace",
            "splith",
            false,
            vec![floating_wrapper.clone()],
        );
        let path = vec![&leaf, &floating_wrapper, &ws];
        let eligible = vec![&ws];

        let plan = plan_layout(Action::Tab, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(plan, LayoutPlan::NoOp);
    }

    #[test]
    fn test_plan_layout_container_focused_already_tabbed_idempotent() {
        let leaf = node(101, "con", "none", false, vec![]);
        let inner = node(20, "con", "tabbed", true, vec![leaf.clone()]);
        let ws = node(10, "workspace", "tabbed", false, vec![inner.clone()]);
        let path = vec![&leaf, &inner, &ws];
        let eligible = vec![&inner, &ws];

        // Focus is on inner (already tabbed), and ws above it is also already tabbed.
        // It must NOT re-execute layout tabbed; it must return FocusLeaf!
        let plan = plan_layout(Action::Tab, &inner, &leaf, &path, &eligible, true);
        assert_eq!(plan, LayoutPlan::FocusLeaf(101));
    }

    #[test]
    fn test_plan_layout_tab_fullscreen_preservation() {
        let mut leaf = node(101, "con", "none", true, vec![]);
        leaf.fullscreen_mode = 1;
        let ws = node(10, "workspace", "tabbed", false, vec![leaf.clone()]);
        let path = vec![&leaf, &ws];
        let eligible = vec![&ws];

        let plan = plan_layout(Action::Tab, &leaf, &leaf, &path, &eligible, false);
        assert_eq!(
            plan,
            LayoutPlan::ExecuteCommand("[con_id=101] focus; [con_id=101] fullscreen enable".into())
        );
    }
}
