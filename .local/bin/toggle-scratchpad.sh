#!/usr/bin/env bash

# If scratchpad terminal doesn't exist, spawn it
if ! xdotool search --classname "scratchpad_term" 2>/dev/null | grep -q [0-9]; then
    kitty --class scratchpad_term --title __scratchpad_term__ &
    for i in {1..20}; do
        if xdotool search --classname "scratchpad_term" 2>/dev/null | grep -q [0-9]; then
            break
        fi
        sleep 0.05
    done
fi

# Toggle scratchpad visibility and ensure centered position
FOCUSED_ID=$(xdotool getactivewindow 2>/dev/null)
SCRATCH_ID=$(xdotool search --classname "scratchpad_term" 2>/dev/null | tail -1)

if [ -n "$SCRATCH_ID" ] && [ "$FOCUSED_ID" = "$SCRATCH_ID" ]; then
    i3-msg '[instance="scratchpad_term"] move to scratchpad'
else
    i3-msg '[instance="scratchpad_term"] scratchpad show, floating enable, resize set 900 550, move position center, focus'
fi
