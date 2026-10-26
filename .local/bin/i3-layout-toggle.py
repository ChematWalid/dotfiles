#!/usr/bin/env python3
"""
i3-layout-toggle.py

Robust and reliable layout switcher for i3 window manager.
Actions:
  - tab: switches the active container/group to tabbed layout (hierarchical, idempotent, leaf-focus preserving)
  - toggle / untab / split: untabs tabbed containers from inside out, or toggles split orientation (splith <-> splitv)

Diagnoses and resolves i3 container hierarchy & focus issues:
  1. Prevents focus loss to workspace/output/root containers
  2. Guarantees leaf window retains keyboard focus across all transitions
  3. Correctly identifies multi-window grouping containers under autotiling splits
  4. Eliminates redundant single-child container nesting (zero Russian doll container growth)
  5. Recovers active leaf focus via MRU focus history (con.focus[0]) rather than naive leaves[0]
  6. Preserves fullscreen mode across layout transitions
  7. Protects against concurrent execution races using file locking
"""

import os
import sys
import fcntl
import i3ipc


def acquire_lock():
    """
    Prevents concurrent executions from racing and corrupting i3 tree state.
    """
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    lock_file = os.path.join(runtime_dir, "i3-layout-toggle.lock")
    try:
        lock_fd = open(lock_file, "w")
        fcntl.flock(lock_fd, fcntl.LOCK_EX)
        return lock_fd
    except Exception:
        return None


def find_mru_leaf(con):
    """
    Recursively descends a container following most-recently-used focus
    order (con.focus[0]) to find the true active leaf window.
    """
    curr = con
    while curr and len(curr.nodes) > 0:
        if hasattr(curr, "focus") and curr.focus:
            child_id = curr.focus[0]
            found = [n for n in curr.nodes if n.id == child_id]
            if found:
                curr = found[0]
                continue
        curr = curr.nodes[0]
    return curr


def get_active_leaf(tree, focused):
    """
    Ensures we have an active leaf window. If focus is at root, output,
    content, workspace, or intermediate container level, recovers the active
    leaf on the visible workspace using MRU focus order.
    """
    if focused is None:
        return None

    # Focus escaped above workspace (root, output, content)
    if focused.type in ("root", "output") or focused.name == "content":
        ws = next((w for w in tree.workspaces() if w.focused or w.visible), None)
        if not ws:
            return None
        return find_mru_leaf(ws)

    # Focus at workspace level
    if focused.type == "workspace":
        return find_mru_leaf(focused)

    # Focus at intermediate container level
    if len(focused.nodes) > 0:
        return find_mru_leaf(focused)

    return focused


def build_container_path(leaf):
    """
    Builds the path from the leaf window up to the workspace.
    path[0] is the leaf window.
    path[-1] is the workspace.
    """
    path = [leaf]
    curr = leaf.parent
    while curr:
        path.append(curr)
        if curr.type == "workspace":
            break
        curr = curr.parent
    return path


def get_eligible_grouping_containers(path):
    """
    Returns eligible grouping containers in path[1:] (from innermost to outermost).
    Excludes autotiling single-child wrappers where sibling windows exist in parent,
    while preserving single-window workspace containers to prevent redundant nesting.
    """
    if len(path) <= 1:
        return []

    if len(path) == 2:
        # [leaf, workspace]
        return [path[1]]

    ws = path[-1]
    eligible = []

    for idx in range(1, len(path)):
        con = path[idx]
        if con.type == "workspace":
            if len(con.nodes) > 1 or not eligible:
                eligible.append(con)
        else:
            # con.type == 'con'
            if len(con.nodes) > 1:
                eligible.append(con)
            elif con.layout in ("tabbed", "stacked"):
                eligible.append(con)
            elif con.parent == ws and len(ws.nodes) == 1:
                # Sole container on single-window workspace
                eligible.append(con)

    if not eligible:
        eligible = [path[1]]

    return eligible


def execute_layout(i3, target, child, leaf, layout_cmd, was_fullscreen, was_container_focused):
    """
    Executes the layout change on the target container and guarantees keyboard
    focus returns to the active leaf window without losing fullscreen state.
    """
    if child.id == leaf.id and not was_container_focused:
        # Leaf is already focused in i3: apply directly without switching focus
        cmd = layout_cmd
    else:
        # Child is an intermediate container, or focus was at container level
        cmd = f"[con_id={child.id}] focus; {layout_cmd}; [con_id={leaf.id}] focus"

    if was_fullscreen:
        cmd += f"; [con_id={leaf.id}] fullscreen enable"

    i3.command(cmd)


def main():
    action = sys.argv[1].lower() if len(sys.argv) > 1 else "toggle"

    if action in ("-h", "--help"):
        print("Usage: i3-layout-toggle.py [tab|toggle|untab|split]")
        sys.exit(0)

    lock_fd = acquire_lock()

    try:
        i3 = i3ipc.Connection()
    except Exception as e:
        sys.stderr.write(f"i3-layout-toggle: failed to connect to i3 IPC: {e}\n")
        sys.exit(1)

    tree = i3.get_tree()
    focused = tree.find_focused()
    if not focused:
        sys.exit(0)

    # Detect if user explicitly focused a parent container / workspace (e.g. via $mod+a)
    was_container_focused = (len(focused.nodes) > 0)

    leaf = get_active_leaf(tree, focused)
    if leaf is None:
        # Empty workspace: toggle workspace layout directly
        if action == "tab":
            i3.command("layout tabbed")
        else:
            i3.command("layout toggle split")
        sys.exit(0)

    # Do not alter tiling layout on floating windows
    if leaf.floating and "_on" in leaf.floating:
        sys.exit(0)

    path = build_container_path(leaf)
    eligible = get_eligible_grouping_containers(path)
    was_fullscreen = (getattr(leaf, "fullscreen_mode", 0) != 0)

    if action == "tab":
        if was_container_focused and focused in path:
            f_idx = path.index(focused)
            if focused.layout in ("tabbed", "stacked"):
                # Container already tabbed: climb to next eligible container above
                higher = [c for c in eligible if path.index(c) > f_idx]
                target = higher[0] if higher else focused
            else:
                target = focused
        else:
            # Normal leaf focus: find innermost eligible container not already tabbed/stacked
            untabbed = [c for c in eligible if c.layout not in ("tabbed", "stacked")]
            if untabbed:
                target = untabbed[0]
            else:
                # All eligible containers already tabbed: idempotent, guarantee focus
                i3.command(f"[con_id={leaf.id}] focus")
                sys.exit(0)

        child = path[path.index(target) - 1]
        execute_layout(i3, target, child, leaf, "layout tabbed", was_fullscreen, was_container_focused)

    else:
        # untab / toggle split
        if was_container_focused and focused in path:
            target = focused
        else:
            # Untab the innermost tabbed/stacked container
            tabbed_con = next((c for c in eligible if c.layout in ("tabbed", "stacked")), None)
            if tabbed_con:
                target = tabbed_con
            else:
                # None are tabbed: toggle split orientation (splith <-> splitv)
                target = eligible[0]

        child = path[path.index(target) - 1]
        execute_layout(i3, target, child, leaf, "layout toggle split", was_fullscreen, was_container_focused)


if __name__ == "__main__":
    main()
