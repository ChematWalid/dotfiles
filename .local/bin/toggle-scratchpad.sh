#!/usr/bin/env bash
# ── toggle-scratchpad.sh ──────────────────────────────────────────────────────
# Fast Floating Dropdown Terminal (Kitty) with override-redirect preload.

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
        [[ -n "$scratch_id" ]] && break
        sleep 0.02
    done
    exit 0
fi

# 1-press toggle: if visible, hide; if hidden, show and focus
if xwininfo -id "$scratch_id" 2>/dev/null | grep -q "IsViewable"; then
    xdotool windowunmap "$scratch_id" 2>/dev/null || true
else
    xdotool windowmap "$scratch_id" 2>/dev/null || true
    xdotool windowfocus "$scratch_id" 2>/dev/null || true
fi
