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
readonly LOCK_FILE="/tmp/.scratchpad-toggle.lock"
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    exit 0
fi
trap 'exec 200>&-' EXIT

# 2. Key-repeat debounce (200ms threshold matching X11 key repeat)
readonly STAMP_FILE="/tmp/.scratchpad-toggle.stamp"
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
readonly FS_STATE_FILE="/tmp/.scratchpad-fs.state"

# 3. Query i3 tree state in a single fast call (~8ms)
tree_info=$(i3-msg -t get_tree 2>/dev/null || echo "{}")

current_ws=$(i3-msg -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' || echo "")

scratch_ws=$(echo "$tree_info" | jq -r '
  [.. | select(.type? == "workspace") | select(.. | .window_properties?.instance? == "'"$CLASS_NAME"'")] | .[0]?.name // ""
' 2>/dev/null || echo "")

fullscreen_id=$(echo "$tree_info" | jq -r '
  [.. | select(.focused? == true and .fullscreen_mode? == 1)] | .[0]?.id // 0
' 2>/dev/null || echo "0")

# 4. Handle scratchpad state
if [[ -z "$scratch_ws" ]]; then
    # Window does not exist yet -> remember fullscreen if active, spawn and show
    if [[ "$fullscreen_id" -ne 0 ]]; then
        echo "$fullscreen_id" > "$FS_STATE_FILE"
    fi

    # Spawn kitty via i3 so it is properly managed and detached
    i3-msg "exec --no-startup-id kitty --class $CLASS_NAME --title $TITLE" >/dev/null 2>&1

    # Wait briefly for kitty to register in i3 tree (max 500ms)
    for _ in {1..25}; do
        if i3-msg -t get_tree 2>/dev/null | grep -q "\"instance\":\"$CLASS_NAME\""; then
            break
        fi
        sleep 0.02
    done

    i3-msg '[instance="'"$CLASS_NAME"'"] scratchpad show, floating enable, resize set 900 550, move position center, focus' >/dev/null 2>&1 || true
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
