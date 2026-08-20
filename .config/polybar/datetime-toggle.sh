#!/usr/bin/env bash

STATE_FILE="/tmp/polybar-datetime-state"
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

# Cycle states: 0 -> 1 -> 2 -> 0
NEXT_STATE=$(( (STATE + 1) % 3 ))
echo "$NEXT_STATE" > "$STATE_FILE"

# Signal tail script to update immediately
pkill -USR1 -f datetime-tail.sh
