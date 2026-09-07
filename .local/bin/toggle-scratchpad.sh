#!/usr/bin/env bash
# ── toggle-scratchpad.sh ──────────────────────────────────────────────────────
# Fast Floating Dropdown Terminal (Kitty) with override-redirect preload.
# Guarantees top-level Z-stack placement on top of all windows and clean toggle.

set -euo pipefail

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

# Check if visible and if it currently holds input focus
is_viewable=$(xwininfo -id "$scratch_id" 2>/dev/null | grep -c "IsViewable" || true)
current_focus=$(xdotool getwindowfocus 2>/dev/null || true)

if [[ "$is_viewable" -gt 0 ]] && [[ "$current_focus" == "$scratch_id" ]]; then
    # Already visible AND currently focused -> hide
    xdotool windowunmap "$scratch_id" 2>/dev/null || true
else
    # Either hidden OR buried under another window -> map, raise to top, and focus
    xdotool windowmap "$scratch_id" 2>/dev/null || true
    xdotool windowraise "$scratch_id" 2>/dev/null || true
    xdotool windowfocus "$scratch_id" 2>/dev/null || true
fi
