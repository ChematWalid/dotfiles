#!/usr/bin/env bash
# ── network-toggle-fast.sh ────────────────────────────────────────────────────
# Toggles network module display between SSID and IP address via SIGUSR1.

set -euo pipefail

readonly STATE_FILE="/tmp/polybar-network-state"

if [[ -f "$STATE_FILE" ]]; then
    rm -f "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

pkill -USR1 -f network-tail.sh 2>/dev/null || true
