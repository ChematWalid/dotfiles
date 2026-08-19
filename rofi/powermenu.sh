#!/usr/bin/env bash
chosen=$(printf "  Power Off\n  Restart\n  Suspend\n  Log Out\n  Lock" | rofi -dmenu -i -p "System")
case "$chosen" in
    "  Power Off") systemctl poweroff ;;
    "  Restart") systemctl reboot ;;
    "  Suspend") systemctl suspend ;;
    "  Log Out") i3-msg exit ;;
    "  Lock") i3lock -c 1e1e2e ;;
esac
