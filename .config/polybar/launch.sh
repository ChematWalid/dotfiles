#!/usr/bin/env bash
killall -9 polybar 2>/dev/null
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done
DISPLAY=:0 polybar main -c ~/.config/polybar/config.ini > /tmp/polybar.log 2>&1 &
