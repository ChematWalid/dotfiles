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
if [[ -n "${EPOCHREALTIME:-}" ]]; then
    now="${EPOCHREALTIME/./}"
    now="${now:0:${#now}-3}"
else
    now=$(date +%s%3N 2>/dev/null || date +%s)
fi
if [[ -f "$STAMP_FILE" ]]; then
    last=0
    IFS= read -r last < "$STAMP_FILE" || true
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
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
    tree=$(i3-msg -t get_tree) || return 1
    jq -r --arg instance "$CLASS_NAME" \
        'first(.. | objects | select(.window_properties?.instance? == $instance) | .id) // empty' \
        <<< "$tree"
}

run_i3_command() {
    local command="$1"
    local response
    if ! response=$(i3-msg "$command" 2>&1); then
        printf 'toggle-scratchpad: i3 command failed: %s\n' "$response" >&2
        return 1
    fi
    if ! jq -e 'type == "array" and length > 0 and all(.[]; .success == true)' \
        >/dev/null <<< "$response"; then
        printf 'toggle-scratchpad: i3 rejected command (%s): %s\n' \
            "$command" "$response" >&2
        return 1
    fi
}

# 3. Query i3 state once; the focused workspace is present in the same tree.
if ! tree_info=$(i3-msg -t get_tree 2>&1); then
    printf 'toggle-scratchpad: could not read i3 window tree: %s\n' "$tree_info" >&2
    exit 1
fi

# Derive the scratchpad workspace, focused workspace, and fullscreen window in
# one jq invocation instead of making a second IPC request and parser process.
# Keep the workspace lookup scoped to nodes containing our scratchpad,
# including the hidden __i3_scratch workspace.
if ! tree_state_output=$(jq -er --arg instance "$CLASS_NAME" '
  [
    (first(.. | objects | select(.type? == "workspace")
      | select(.. | .window_properties?.instance? == $instance) | .name) // ""),
    (first(.. | objects | select(.type? == "workspace")
      | select(any(.. | objects; .focused? == true)) | .name) // ""),
    (first(.. | objects | select(.focused? == true and .fullscreen_mode? == 1)
      | .id) // 0)
  ][]
' <<< "$tree_info"); then
    printf 'toggle-scratchpad: could not parse i3 window tree\n' >&2
    exit 1
fi
mapfile -t tree_state <<< "$tree_state_output"
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
    coproc I3_EVENTS {
        exec 200>&-
        exec i3-msg -t subscribe -m '["window"]'
    }
    event_fd="${I3_EVENTS[0]}"
    event_pid="$I3_EVENTS_PID"
    cleanup_event_listener() {
        kill "$event_pid" 2>/dev/null || true
        wait "$event_pid" 2>/dev/null || true
    }
    trap cleanup_event_listener EXIT

    # Spawn kitty via i3 so it is properly managed and detached
    run_i3_command "exec --no-startup-id kitty --class $CLASS_NAME --title $TITLE"

    # Query once for the case where Kitty mapped before the event stream became
    # readable. After that, ignore unrelated focus/title events without
    # repeatedly fetching and parsing i3's full window tree.
    if ! window_id=$(find_scratchpad_id); then
        printf 'toggle-scratchpad: could not query for the new Kitty window\n' >&2
        exit 1
    fi
    deadline=$((SECONDS + 5))
    while [[ -z "$window_id" ]]; do
        remaining=$((deadline - SECONDS))
        (( remaining > 0 )) || break
        if ! IFS= read -r -t "$remaining" event <&"$event_fd"; then
            break
        fi

        # The window event is emitted once i3 has reparented the new client.
        window_id=$(jq -r --arg instance "$CLASS_NAME" '
            select(.change == "new"
              and .container.window_properties?.instance? == $instance)
            | .container.id // empty
        ' <<< "$event" 2>/dev/null || true)
    done

    # Cover a lost/late event with one final state query after the wait.
    if [[ -z "$window_id" ]]; then
        if ! window_id=$(find_scratchpad_id); then
            printf 'toggle-scratchpad: could not query for the new Kitty window\n' >&2
            exit 1
        fi
    fi

    cleanup_event_listener
    trap - EXIT

    if [[ -z "$window_id" ]]; then
        exit 1
    fi

    run_i3_command "[id=\"$window_id\"] scratchpad show, floating enable, resize set 900 550, move position center, focus"
    exit 0
fi

if [[ -n "$current_ws" && "$scratch_ws" == "$current_ws" ]]; then
    # Scratchpad is currently visible on the current workspace -> HIDE IT
    run_i3_command "[instance=\"$CLASS_NAME\"] move to scratchpad"

    # Restore fullscreen if a window was fullscreen before scratchpad opened
    if [[ -f "$FS_STATE_FILE" ]]; then
        fs_id=0
        IFS= read -r fs_id < "$FS_STATE_FILE" || true
        [[ "$fs_id" =~ ^[0-9]+$ ]] || fs_id=0
        rm -f "$FS_STATE_FILE"
        if [[ -n "$fs_id" && "$fs_id" != "0" ]]; then
            run_i3_command "[id=\"$fs_id\"] fullscreen enable"
        fi
    fi
else
    # Scratchpad is hidden in __i3_scratch (or on another workspace) -> SHOW IT HERE
    if [[ "$fullscreen_id" -ne 0 ]]; then
        echo "$fullscreen_id" > "$FS_STATE_FILE"
    else
        rm -f "$FS_STATE_FILE"
    fi

    run_i3_command "[instance=\"$CLASS_NAME\"] scratchpad show, floating enable, resize set 900 550, move position center, focus"
fi
