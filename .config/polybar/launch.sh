#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.1; done
nohup polybar main >/tmp/polybar-debug.log 2>&1 &
