#!/usr/bin/env bash
# ── network-tail.sh ───────────────────────────────────────────────────────────
# Event-driven network status for Polybar with toggleable SSID / IP view.
# Uses nmcli monitor for zero-polling D-Bus updates and USR1 for instant toggle.

set -euo pipefail

readonly STATE_FILE="/tmp/polybar-network-state"

update() {
    if [[ -f "$STATE_FILE" ]]; then
        local ip
        ip=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1 || true)
        if [[ -z "$ip" ]]; then
            echo "󰤭 Disconnected"
        else
            echo "󰤨 $ip"
        fi
    else
        local ssid
        ssid=$(iwgetid -r 2>/dev/null || true)
        if [[ -z "$ssid" ]]; then
            echo "󰤭 Disconnected"
        else
            echo "󰤨 $ssid"
        fi
    fi
}

trap "update" USR1

# Emit initial status
update

# Stream NetworkManager events asynchronously and trigger update on changes
nmcli monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"connected"*|*"disconnected"*|*"connecting"*|*"activated"*|*"deactivated"*)
            update
            ;;
    esac
done &
NM_PID=$!

trap 'kill "$NM_PID" 2>/dev/null || true; exit 0' EXIT INT TERM

wait "$NM_PID" 2>/dev/null || true
