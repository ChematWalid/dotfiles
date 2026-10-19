#!/usr/bin/env bash
# ── window-info.sh ────────────────────────────────────────────────────────────
# Displays focused window metadata via notification and copies class to clipboard.

set -euo pipefail

# Query i3 once and extract every field in one jq process. @tsv keeps unusual
# tabs/newlines in window titles escaped so they cannot shift the fields.
window_info=$(i3-msg -t get_tree 2>/dev/null | jq -r '
    first(recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true))
    | [ .window_properties.class // "",
        .window_properties.instance // "",
        .window_properties.title // .name // "",
        .window // "" ]
    | @tsv
' 2>/dev/null || true)

win_class=""
win_instance=""
win_title=""
win_xid=""
if [[ -n "$window_info" ]]; then
    IFS=$'\t' read -r win_class win_instance win_title win_xid <<< "$window_info"
fi

# Fallback to xdotool / xprop if i3 didn't yield properties
if [[ -z "$win_class" ]]; then
    active_xid=$(xdotool getactivewindow 2>/dev/null || true)
    if [[ -n "$active_xid" ]]; then
        win_xid="$active_xid"
        wm_class=$(xprop -id "$win_xid" WM_CLASS 2>/dev/null || true)
        # WM_CLASS is printed as: WM_CLASS(STRING) = "instance", "class".
        # Split and remove the quotes in Bash instead of starting awk twice.
        if [[ "$wm_class" == *' = '* ]]; then
            wm_class=${wm_class#*= }
            IFS=, read -r win_instance win_class <<< "$wm_class"
            win_instance=${win_instance//\"/}
            win_class=${win_class//\"/}
            win_instance=${win_instance# }
            win_class=${win_class# }
        fi
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
    pid_line=$(xprop -id "$win_xid" _NET_WM_PID 2>/dev/null || true)
    extracted_pid=${pid_line##*= }
    if [[ "$extracted_pid" =~ ^[0-9]+$ ]]; then
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
