#!/usr/bin/env bash
# ── window-info.sh ────────────────────────────────────────────────────────────
# Displays focused window metadata via notification and copies class to clipboard.

set -euo pipefail

# Query i3 for focused container
focused_json=$(i3-msg -t get_tree 2>/dev/null | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true)' 2>/dev/null || true)

win_class=""
win_instance=""
win_title=""
win_xid=""

if [[ -n "$focused_json" ]]; then
    win_class=$(echo "$focused_json" | jq -r '.window_properties.class // empty' 2>/dev/null || true)
    win_instance=$(echo "$focused_json" | jq -r '.window_properties.instance // empty' 2>/dev/null || true)
    win_title=$(echo "$focused_json" | jq -r '.window_properties.title // .name // empty' 2>/dev/null || true)
    win_xid=$(echo "$focused_json" | jq -r '.window // empty' 2>/dev/null || true)
fi

# Fallback to xdotool / xprop if i3 didn't yield properties
if [[ -z "$win_class" ]]; then
    active_xid=$(xdotool getactivewindow 2>/dev/null || true)
    if [[ -n "$active_xid" ]]; then
        win_xid="$active_xid"
        wm_class=$(xprop -id "$win_xid" WM_CLASS 2>/dev/null || true)
        win_instance=$(echo "$wm_class" | awk -F '"' '{print $2}')
        win_class=$(echo "$wm_class" | awk -F '"' '{print $4}')
        win_title=$(xdotool getwindowname "$win_xid" 2>/dev/null || true)
    fi
fi

if [[ -z "$win_class" && -z "$win_title" ]]; then
    notify-send -u low -a "i3wm" -i dialog-information "Window Info" "No active client window focused." 2>/dev/null || true
    exit 0
fi

proc_name="N/A"
pid="N/A"
if [[ -n "$win_xid" ]]; then
    extracted_pid=$(xprop -id "$win_xid" _NET_WM_PID 2>/dev/null | awk '{print $3}' || true)
    if [[ -n "$extracted_pid" ]]; then
        pid="$extracted_pid"
        proc_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "N/A")
    fi
fi

# Copy class to clipboard for quick i3 configuration
if [[ -n "$win_class" ]]; then
    printf '%s' "$win_class" | xclip -selection clipboard 2>/dev/null || true
fi

summary="Focused Window: ${win_class:-Unknown}"
body="<b>Class:</b> <code>${win_class:-N/A}</code> (<i>copied to clipboard</i>)\n<b>Instance:</b> <code>${win_instance:-N/A}</code>\n<b>Process:</b> <code>${proc_name}</code> (PID: ${pid})\n<b>Title:</b> ${win_title:-N/A}"

notify-send -u normal -a "i3wm" -i preferences-desktop-display "$summary" "$body" 2>/dev/null || true
