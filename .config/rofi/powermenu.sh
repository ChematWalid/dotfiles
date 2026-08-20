#!/usr/bin/env bash
chosen=$(printf "  Power Off\n  Restart\n  Suspend\n  Log Out\n  Lock" | \
    rofi -dmenu -i -p "  System" \
    -theme ~/.config/rofi/config.rasi \
    -theme-str 'window {width: 300px; height: 280px;} listview {lines: 5;}')
case "$chosen" in
    "  Power Off") systemctl poweroff ;;
    "  Restart") systemctl reboot ;;
    "  Suspend") systemctl suspend ;;
    "  Log Out") i3-msg exit ;;
    "  Lock") /home/walid/.local/bin/lock.sh ;;
esac
