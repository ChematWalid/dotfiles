#!/usr/bin/env bash
# Toggle Polybar visibility on demand (Alt + F)
if pgrep -u $UID -x polybar >/dev/null; then
    polybar-msg cmd toggle
else
    ~/.config/polybar/launch.sh
    sleep 0.2
    polybar-msg cmd show
fi
