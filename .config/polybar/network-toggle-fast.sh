#!/bin/bash
STATE_FILE="/tmp/polybar-network-state"
if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi
# Find the PID of network-tail.sh and send USR1
pkill -USR1 -f network-tail.sh
