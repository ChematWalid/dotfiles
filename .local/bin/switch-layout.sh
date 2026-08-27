#!/usr/bin/env bash
# ── Toggle Keyboard Layout between BE and ARA ──

CURRENT=$(setxkbmap -query | awk '/layout/{print $2}' | cut -d',' -f1)

if [ "$CURRENT" = "be" ]; then
    setxkbmap -layout "ara,be" -option "grp:win_space_toggle"
    LAYOUT_NAME="Arabic (العربية)"
    FLAG="🇸🇦"
else
    setxkbmap -layout "be,ara" -option "grp:win_space_toggle"
    LAYOUT_NAME="Belgian (AZERTY)"
    FLAG="🇧🇪"
fi

# Ensure repeat rate (250ms delay, 50 repeats/sec) is maintained
xset r rate 250 50 2>/dev/null || true

# Send Dunst OSD notification
if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Keyboard" -r 9993 -u low -i input-keyboard "Keyboard Layout" "$FLAG $LAYOUT_NAME" -t 1500
fi
