#!/usr/bin/env bash

# If scratchpad terminal doesn't exist, spawn it
if ! xdotool search --classname "scratchpad_term" 2>/dev/null | grep -q [0-9]; then
    kitty --class scratchpad_term --title __scratchpad_term__ &
    sleep 0.3
fi

i3-msg '[instance="scratchpad_term"] scratchpad show'
