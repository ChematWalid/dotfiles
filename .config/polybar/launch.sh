#!/usr/bin/env bash
killall -9 polybar 2>/dev/null
pkill -9 -f "mpris-live.py" 2>/dev/null
pkill -9 -f "datetime-tail.sh" 2>/dev/null
pkill -9 -f "network-tail.sh" 2>/dev/null
killall -9 playerctl 2>/dev/null
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done
DISPLAY="${DISPLAY:-:0}" nohup polybar main -c ~/.config/polybar/config.ini > /tmp/polybar.log 2>&1 &
