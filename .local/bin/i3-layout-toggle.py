#!/usr/bin/env python3
"""
i3-layout-toggle.py

Reliable layout switcher for i3 window manager.
Actions:
  - tab: switches the active container/window to tabbed layout (idempotent, leaf-focus preserving)
  - toggle / untab: switches a tabbed container back to split, or toggles split orientation (splith <-> splitv)

Diagnoses and resolves i3 container hierarchy & focus issues:
  1. Prevents focus loss to workspace/output/root containers
  2. Guarantees leaf window retains keyboard focus across all transitions
  3. Properly targets multi-window grouping containers across autotiling splits
  4. Avoids nesting redundant single-child containers
  5. Recovers gracefully if focus is ever caught at container/workspace/root level
"""

import sys
import i3ipc


def get_active_leaf(tree, focused):
    """
    Ensures we have a focused leaf window. If focus is at root, output,
    content, or workspace level, recover the active leaf on the visible workspace.
    """
    if focused is None:
        return None

    # Escaped above workspace (content, output, root)
    if focused.type in ('root', 'output') or focused.name == 'content':
        ws = next((w for w in tree.workspaces() if w.focused or w.visible), None)
        if not ws:
            return None
        leaves = ws.leaves()
        return leaves[0] if leaves else None

    # Workspace level focus
    if focused.type == 'workspace':
        leaves = focused.leaves()
        return leaves[0] if leaves else None

    # Intermediate container level focus
    if len(focused.nodes) > 0:
        leaves = focused.leaves()
        return leaves[0] if leaves else focused

    return focused


def build_container_path(leaf):
    """
    Builds the path from the leaf window up to the workspace.
    path[0] is the leaf window.
    path[-1] is the workspace.
    """
    path = [leaf]
    curr = leaf.parent
    while curr and curr.type in ('con', 'workspace'):
        path.append(curr)
        if curr.type == 'workspace':
            break
        curr = curr.parent
    return path


def main():
    action = sys.argv[1].lower() if len(sys.argv) > 1 else "toggle"

    if action in ("-h", "--help"):
        print("Usage: i3-layout-toggle.py [tab|toggle|untab|split]")
        sys.exit(0)

    try:
        i3 = i3ipc.Connection()
    except Exception as e:
        sys.stderr.write(f"i3-layout-toggle: failed to connect to i3 IPC: {e}\n")
        sys.exit(1)

    tree = i3.get_tree()
    focused = tree.find_focused()
    if not focused:
        sys.exit(0)

    # Detect if user explicitly focused a parent container (e.g. via $mod+a)
    was_container_focused = (focused.type == 'con' and len(focused.nodes) > 0)

    leaf = get_active_leaf(tree, focused)
    if leaf is None:
        # Empty workspace: just toggle workspace layout directly
        if action == "tab":
            i3.command("layout tabbed")
        else:
            i3.command("layout toggle split")
        sys.exit(0)

    # Do not alter tiling layout on floating windows
    if leaf.floating and "_on" in leaf.floating:
        sys.exit(0)

    path = build_container_path(leaf)

    # Case 1: The user explicitly focused an ancestor container (via $mod+a)
    if was_container_focused and focused in path:
        focused_idx = path.index(focused)
        if action == "tab":
            if focused.layout in ("tabbed", "stacked") and focused_idx < len(path) - 1:
                # User wants to tab the container above it
                target_idx = focused_idx + 1
                child = path[target_idx - 1]
                i3.command(f"[con_id={child.id}] focus; layout tabbed; [con_id={leaf.id}] focus")
                sys.exit(0)
            else:
                child = path[focused_idx - 1]
                i3.command(f"[con_id={child.id}] focus; layout tabbed; [con_id={leaf.id}] focus")
                sys.exit(0)
        else:
            # untab / toggle split
            child = path[focused_idx - 1]
            i3.command(f"[con_id={child.id}] focus; layout toggle split; [con_id={leaf.id}] focus")
            sys.exit(0)

    # Case 2: Normal window focus
    if action == "tab":
        # Check if already inside a tabbed / stacked container
        for idx in range(1, len(path)):
            if path[idx].layout in ("tabbed", "stacked"):
                # Already tabbed: idempotent, guarantee leaf focus
                i3.command(f"[con_id={leaf.id}] focus")
                sys.exit(0)

        # Find the container grouping this window with other windows
        target_idx = None
        for idx in range(1, len(path)):
            if len(path[idx].nodes) > 1 or path[idx].type == "workspace":
                target_idx = idx
                break
        target_idx = target_idx or (len(path) - 1)
        child = path[target_idx - 1]
        i3.command(f"[con_id={child.id}] focus; layout tabbed; [con_id={leaf.id}] focus")

    else:
        # untab / toggle split
        # If any container in path is tabbed/stacked, untab it
        target_idx = None
        for idx in range(1, len(path)):
            if path[idx].layout in ("tabbed", "stacked"):
                target_idx = idx
                break

        if target_idx is None:
            # Already split: toggle orientation (splith <-> splitv) on the grouping container
            for idx in range(1, len(path)):
                if len(path[idx].nodes) > 1 or path[idx].type == "workspace":
                    target_idx = idx
                    break
            target_idx = target_idx or (len(path) - 1)

        child = path[target_idx - 1]
        i3.command(f"[con_id={child.id}] focus; layout toggle split; [con_id={leaf.id}] focus")


if __name__ == "__main__":
    main()
