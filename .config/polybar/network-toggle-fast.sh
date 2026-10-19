#!/usr/bin/env bash
# ── network-toggle-fast.sh ────────────────────────────────────────────────────
# Toggles network module display between SSID and IP address via SIGUSR1.

set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
readonly STATE_FILE="${STATE_DIR}/polybar-network-state"
mkdir -p "$STATE_DIR"

if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

pkill -USR1 -f network-tail.sh 2>/dev/null || true
