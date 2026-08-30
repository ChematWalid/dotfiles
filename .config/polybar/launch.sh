#!/usr/bin/env bash
killall -9 polybar 2>/dev/null
pkill -9 -f "mpris-live.py" 2>/dev/null
pkill -9 -f "datetime-tail.sh" 2>/dev/null
pkill -9 -f "network-tail.sh" 2>/dev/null
killall -9 playerctl 2>/dev/null
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done

DISPLAY="${DISPLAY:-:0}" nohup polybar main -c ~/.config/polybar/config.ini > /tmp/polybar.log 2>&1 &

# Wait for IPC socket to initialize and hide Polybar by default
for i in {1..20}; do
    if polybar-msg cmd hide 2>/dev/null; then
        break
    fi
    sleep 0.05
done
