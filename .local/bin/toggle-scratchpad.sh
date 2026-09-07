#!/usr/bin/env bash
# ── toggle-scratchpad.sh ──────────────────────────────────────────────────────
# Fast Floating Dropdown Terminal (Kitty) with override-redirect preload.
# Features:
#  - Top-level Z-stack placement (always above all normal windows)
#  - Atomic non-blocking flock + 250ms timestamp debounce (prevents repeat bounces)
#  - Clean 1-press toggle (visible -> hide, hidden -> map + raise + focus)

set -euo pipefail

# Atomic non-blocking lock to eliminate concurrent process races
readonly LOCK_FILE="/tmp/.scratchpad-toggle.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || exit 0

# Cooldown check (250ms debounce matching X11 key-repeat threshold)
readonly STAMP_FILE="/tmp/.scratchpad-toggle.stamp"
now=$(date +%s%3N 2>/dev/null || date +%s)
if [[ -f "$STAMP_FILE" ]]; then
    last=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
    diff=$((now - last))
    if (( diff < 250 )); then
        exit 0
    fi
fi
echo "$now" > "$STAMP_FILE"

readonly LIB_OVERRIDE="${HOME}/.local/lib/libscratchpad_override.so"
readonly CLASS_NAME="scratchpad_term"
readonly TITLE="__scratchpad_term__"

scratch_id=$(xdotool search --classname "$CLASS_NAME" 2>/dev/null | tail -1 || true)

if [[ -n "$scratch_id" ]] && ! xwininfo -id "$scratch_id" >/dev/null 2>&1; then
    scratch_id=""
fi

if [[ -z "$scratch_id" ]]; then
    LD_PRELOAD="$LIB_OVERRIDE" kitty --class "$CLASS_NAME" --title "$TITLE" >/dev/null 2>&1 &

    # Wait briefly for window to be mapped (max 600ms)
    for _ in {1..30}; do
        scratch_id=$(xdotool search --classname "$CLASS_NAME" 2>/dev/null | tail -1 || true)
        if [[ -n "$scratch_id" ]] && xwininfo -id "$scratch_id" >/dev/null 2>&1; then
            xdotool windowraise "$scratch_id" 2>/dev/null || true
            xdotool windowfocus "$scratch_id" 2>/dev/null || true
            break
        fi
        sleep 0.02
    done
    exit 0
fi

# Clean toggle: if visible on screen -> hide; if hidden -> show and focus
is_viewable=$(xwininfo -id "$scratch_id" 2>/dev/null | grep -c "IsViewable" || true)

if [[ "$is_viewable" -gt 0 ]]; then
    xdotool windowunmap "$scratch_id" 2>/dev/null || true
else
    xdotool windowmap "$scratch_id" 2>/dev/null || true
    xdotool windowraise "$scratch_id" 2>/dev/null || true
    xdotool windowfocus "$scratch_id" 2>/dev/null || true
fi
