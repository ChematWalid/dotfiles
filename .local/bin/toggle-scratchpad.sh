#!/usr/bin/env bash
# Fast Floating Dropdown Terminal (Kitty)
# Fullscreen-safe: floats cleanly over any app (including fullscreen video/games)
# without dropping fullscreen or disrupting workspace tiling/splits.
# Backed up original at: ~/.local/bin/toggle-scratchpad.sh.bak

LIB_OVERRIDE="${HOME}/.local/lib/libscratchpad_override.so"
CLASS_NAME="scratchpad_term"
TITLE="__scratchpad_term__"

# Find existing scratchpad window ID
SCRATCH_ID=$(xdotool search --classname "$CLASS_NAME" 2>/dev/null | tail -1)

# Check if the process and window are actually valid
if [ -n "$SCRATCH_ID" ] && ! xwininfo -id "$SCRATCH_ID" >/dev/null 2>&1; then
    SCRATCH_ID=""
fi

if [ -z "$SCRATCH_ID" ]; then
    # Spawn a new instance with override-redirect preload
    LD_PRELOAD="$LIB_OVERRIDE" kitty --class "$CLASS_NAME" --title "$TITLE" &
    
    # Wait briefly for window to be mapped and ready
    for i in {1..30}; do
        SCRATCH_ID=$(xdotool search --classname "$CLASS_NAME" 2>/dev/null | tail -1)
        if [ -n "$SCRATCH_ID" ]; then
            break
        fi
        sleep 0.02
    done
    exit 0
fi

# 1-press toggle: if visible, hide immediately; if hidden, show and focus
if xwininfo -id "$SCRATCH_ID" 2>/dev/null | grep -q "IsViewable"; then
    xdotool windowunmap "$SCRATCH_ID" 2>/dev/null
else
    xdotool windowmap "$SCRATCH_ID" 2>/dev/null
    xdotool windowfocus "$SCRATCH_ID" 2>/dev/null
fi

