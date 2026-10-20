#!/usr/bin/env bash
# ── network-toggle-fast.sh ────────────────────────────────────────────────────
# Toggles the network label between SSID and IP; inotify updates it immediately.

set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
readonly STATE_FILE="${STATE_DIR}/polybar-network-state"
readonly LOCK_FILE="${STATE_DIR}/polybar-network-toggle.lock"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
 
exec 9>"$LOCK_FILE"
flock -w 1 9 || exit 0

if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
else
    : > "$STATE_FILE"
fi
