#!/usr/bin/env bash
# ── datetime-toggle.sh ────────────────────────────────────────────────────────
# Cycles date/time format modes; inotify redraws the Polybar module on close.

set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
readonly STATE_FILE="${STATE_DIR}/polybar-datetime-state"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
state=0
if [[ -r "$STATE_FILE" ]]; then
    IFS= read -r state < "$STATE_FILE" || true
fi
[[ "$state" =~ ^[0-2]$ ]] || state=0

# Cycle states: 0 -> 1 -> 2 -> 0
next_state=$(( (state + 1) % 3 ))
echo "$next_state" > "$STATE_FILE"
