#!/usr/bin/env bash
# ── datetime-toggle.sh ────────────────────────────────────────────────────────
# Cycles date/time format modes; inotify redraws the Polybar module on close.

set -euo pipefail

readonly STATE_FILE="/tmp/polybar-datetime-state"
state=$(cat "$STATE_FILE" 2>/dev/null || echo "0")

# Cycle states: 0 -> 1 -> 2 -> 0
next_state=$(( (state + 1) % 3 ))
echo "$next_state" > "$STATE_FILE"
