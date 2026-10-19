#!/usr/bin/env bash
# ── toggle-scratchpad.sh ──────────────────────────────────────────────────────
# Fast, rock-solid Dropdown Scratchpad Terminal for i3wm.
#
# Features:
#  - Clean 1-press toggle (visible on current workspace -> hide; otherwise -> show)
#  - Never gets stuck regardless of focus state
#  - Debounced (200ms) to prevent key-repeat bounce
#  - Non-leaking atomic flock (closes fd in background children)
#  - Fullscreen restoration (restores fullscreen when scratchpad is hidden)
#  - Centered 900x550 floating geometry
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# 1. Non-blocking concurrency lock (never leak fd to child processes)
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache/dotfiles}"
mkdir -p "$RUNTIME_DIR"
readonly LOCK_FILE="${RUNTIME_DIR}/scratchpad-toggle.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    exit 0
fi
trap 'exec 200>&-' EXIT

# 2. Key-repeat debounce (200ms threshold matching X11 key repeat)
readonly STAMP_FILE="${RUNTIME_DIR}/scratchpad-toggle.stamp"
now=$(date +%s%3N 2>/dev/null || date +%s)
if [[ -f "$STAMP_FILE" ]]; then
    last=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
    diff=$((now - last))
    if (( diff < 200 )); then
        exit 0
    fi
fi
echo "$now" > "$STAMP_FILE"

readonly CLASS_NAME="scratchpad_term"
readonly TITLE="__scratchpad_term__"
readonly FS_STATE_FILE="${RUNTIME_DIR}/scratchpad-fullscreen.state"

find_scratchpad_id() {
    local tree
    tree=$(i3-msg -t get_tree 2>/dev/null) || return 1
    jq -r --arg instance "$CLASS_NAME" \
        'first(.. | objects | select(.window_properties?.instance? == $instance) | .id) // empty' \
        <<< "$tree"
}

# 3. Query i3 state once; the focused workspace is present in the same tree.
tree_info=$(i3-msg -t get_tree 2>/dev/null || echo "{}")

# Derive the scratchpad workspace, focused workspace, and fullscreen window in
# one jq invocation instead of making a second IPC request and parser process.
# Keep the workspace lookup scoped to nodes containing our scratchpad,
# including the hidden __i3_scratch workspace.
mapfile -t tree_state < <(jq -r --arg instance "$CLASS_NAME" '
  [
    (first(.. | objects | select(.type? == "workspace")
      | select(.. | .window_properties?.instance? == $instance) | .name) // ""),
    (first(.. | objects | select(.type? == "workspace")
      | select(any(.. | objects; .focused? == true)) | .name) // ""),
    (first(.. | objects | select(.focused? == true and .fullscreen_mode? == 1)
      | .id) // 0)
  ][]
' <<< "$tree_info")
scratch_ws="${tree_state[0]:-}"
current_ws="${tree_state[1]:-}"
fullscreen_id="${tree_state[2]:-0}"

# 4. Handle scratchpad state
if [[ -z "$scratch_ws" ]]; then
    # Window does not exist yet -> remember fullscreen if active, spawn and show
    if [[ "$fullscreen_id" -ne 0 ]]; then
        echo "$fullscreen_id" > "$FS_STATE_FILE"
    fi

    # Subscribe before launching Kitty; query once after launch to cover the
    # small interval before the event connection is ready, then wait on i3 events.
    coproc I3_EVENTS { i3-msg -t subscribe -m '["window"]'; }
    event_fd="${I3_EVENTS[0]}"
    event_pid="$I3_EVENTS_PID"
    cleanup_event_listener() {
        kill "$event_pid" 2>/dev/null || true
        wait "$event_pid" 2>/dev/null || true
    }
    trap cleanup_event_listener EXIT

    # Spawn kitty via i3 so it is properly managed and detached
    i3-msg "exec --no-startup-id kitty --class $CLASS_NAME --title $TITLE" >/dev/null 2>&1

    window_id=""
    while [[ -z "$window_id" ]]; do
        window_id=$(find_scratchpad_id || true)
        [[ -n "$window_id" ]] && break

        if ! IFS= read -r -t 5 event <&"$event_fd"; then
            break
        fi

        # The window event is emitted once i3 has reparented the new client.
        window_id=$(jq -r --arg instance "$CLASS_NAME" '
            select(.change == "new"
              and .container.window_properties?.instance? == $instance)
            | .container.id // empty
        ' <<< "$event" 2>/dev/null || true)
    done

    cleanup_event_listener
    trap - EXIT

    if [[ -z "$window_id" ]]; then
        exit 1
    fi

    i3-msg "[id=\"$window_id\"] scratchpad show, floating enable, resize set 900 550, move position center, focus" >/dev/null 2>&1 || true
    exit 0
fi

if [[ -n "$current_ws" && "$scratch_ws" == "$current_ws" ]]; then
    # Scratchpad is currently visible on the current workspace -> HIDE IT
    i3-msg '[instance="'"$CLASS_NAME"'"] move to scratchpad' >/dev/null 2>&1 || true

    # Restore fullscreen if a window was fullscreen before scratchpad opened
    if [[ -f "$FS_STATE_FILE" ]]; then
        fs_id=$(cat "$FS_STATE_FILE" 2>/dev/null || echo "0")
        rm -f "$FS_STATE_FILE"
        if [[ -n "$fs_id" && "$fs_id" != "0" ]]; then
            i3-msg "[id=\"$fs_id\"] fullscreen enable" >/dev/null 2>&1 || true
        fi
    fi
else
    # Scratchpad is hidden in __i3_scratch (or on another workspace) -> SHOW IT HERE
    if [[ "$fullscreen_id" -ne 0 ]]; then
        echo "$fullscreen_id" > "$FS_STATE_FILE"
    else
        rm -f "$FS_STATE_FILE"
    fi

    i3-msg '[instance="'"$CLASS_NAME"'"] scratchpad show, floating enable, resize set 900 550, move position center, focus' >/dev/null 2>&1 || true
fi
