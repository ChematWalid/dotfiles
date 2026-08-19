#!/usr/bin/env bash
if pgrep -f "polybar.*tray" >/dev/null; then
    pkill -f "polybar.*tray"
else
    polybar tray 2>&1 >/tmp/polybar-tray.log &
fi
