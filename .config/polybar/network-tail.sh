#!/usr/bin/env bash
# ── network-tail.sh ───────────────────────────────────────────────────────────
# Event-driven network status for Polybar with toggleable SSID / IP view.
# Uses nmcli monitor for zero-polling D-Bus updates and USR1 for instant toggle.

set -euo pipefail

readonly STATE_FILE="/tmp/polybar-network-state"

update() {
    if [[ -f "$STATE_FILE" ]]; then
        local ip
        ip=$(ip -4 -o addr show scope global 2>/dev/null \
            | awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }' || true)
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

# Stream NetworkManager events asynchronously and trigger update on changes.
# Track nmcli itself so a Polybar restart cannot leave its monitor orphaned.
coproc NM_MONITOR { exec nmcli monitor 2>/dev/null; }
NM_PID=$NM_MONITOR_PID

cleanup() {
    trap - EXIT
    kill "$NM_PID" 2>/dev/null || true
    wait "$NM_PID" 2>/dev/null || true
}

trap cleanup EXIT
trap 'exit 0' INT TERM

while IFS= read -r -u "${NM_MONITOR[0]}" line; do
    case "$line" in
        *"connected"*|*"disconnected"*|*"connecting"*|*"activated"*|*"deactivated"*)
            update
            ;;
    esac
done

wait "$NM_PID" 2>/dev/null || true
