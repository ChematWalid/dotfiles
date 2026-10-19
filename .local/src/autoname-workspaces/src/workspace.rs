//! Workspace tree traversal and renaming logic.

use crate::icons::{get_icon, is_ignored};
use crate::ipc::I3Client;
use serde_json::Value;
use std::io;

pub fn get_workspace_number(name: &str) -> &str {
    let digits = name.bytes().take_while(u8::is_ascii_digit).count();
    if digits == 0 {
        name
    } else {
        &name[..digits]
    }
}

pub fn find_workspaces<'a>(node: &'a Value, out: &mut Vec<&'a Value>) {
    if node.get("type").and_then(Value::as_str) == Some("workspace") {
        if node
            .get("name")
            .and_then(Value::as_str)
            .is_some_and(|name| !name.starts_with("__"))
        {
            out.push(node);
        }
        return;
    }

    for key in ["nodes", "floating_nodes"] {
        if let Some(nodes) = node.get(key).and_then(Value::as_array) {
            for child in nodes {
                find_workspaces(child, out);
            }
        }
    }
}

fn quote_i3_string(value: &str) -> String {
    let mut quoted = String::with_capacity(value.len() + 2);
    quoted.push('"');
    for character in value.chars() {
        if matches!(character, '"' | '\\') {
            quoted.push('\\');
        }
        quoted.push(character);
    }
    quoted.push('"');
    quoted
}

fn collect_icons(node: &Value, icons: &mut Vec<&'static str>) {
    let nodes = node
        .get("nodes")
        .and_then(Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[]);
    let floating = node
        .get("floating_nodes")
        .and_then(Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[]);

    if nodes.is_empty() && floating.is_empty() {
        if node.get("window").is_none() && node.get("name").is_none() {
            return;
        }

        let name = node.get("name").and_then(Value::as_str).unwrap_or("");
        let (class, instance) = node
            .get("window_properties")
            .map(|props| {
                (
                    props.get("class").and_then(Value::as_str).unwrap_or(""),
                    props.get("instance").and_then(Value::as_str).unwrap_or(""),
                )
            })
            .unwrap_or(("", ""));

        if !is_ignored(class, instance, name) {
            let icon = get_icon(class, instance, name);
            if !icons.contains(&icon) {
                icons.push(icon);
            }
        }
        return;
    }

    for child in nodes.iter().chain(floating) {
        collect_icons(child, icons);
    }
}

pub fn update_workspaces(client: &mut I3Client) -> io::Result<()> {
    let tree = client.get_tree()?;

    let mut workspaces = Vec::new();
    find_workspaces(&tree, &mut workspaces);

    let mut commands = Vec::with_capacity(workspaces.len());
    for workspace in workspaces {
        let Some(workspace_name) = workspace.get("name").and_then(Value::as_str) else {
            continue;
        };

        let workspace_number = get_workspace_number(workspace_name);
        let mut icons = Vec::new();
        collect_icons(workspace, &mut icons);

        let new_name = if icons.is_empty() {
            workspace_number.to_owned()
        } else {
            format!("{workspace_number} {}", icons.join(" "))
        };

        if workspace_name != new_name {
            commands.push(format!(
                "rename workspace {} to {}",
                quote_i3_string(workspace_name),
                quote_i3_string(&new_name)
            ));
        }
    }

    if commands.is_empty() {
        return Ok(());
    }
    client.run_command(&commands.join("; "))
}

#[cfg(test)]
mod tests {
    use super::get_workspace_number;

    #[test]
    fn extracts_numeric_workspace_prefix_without_allocating() {
        assert_eq!(get_workspace_number("3: browser"), "3");
        assert_eq!(get_workspace_number("12 "), "12");
        assert_eq!(get_workspace_number("web"), "web");
        assert_eq!(get_workspace_number("٣ browser"), "٣ browser");
    }
}
