#!/usr/bin/env bash
# ── network-tail.sh ───────────────────────────────────────────────────────────
# Event-driven network status for Polybar with toggleable SSID / IP view.
# Uses nmcli monitor for zero-polling D-Bus updates and USR1 for instant toggle.

set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
readonly STATE_FILE="${STATE_DIR}/polybar-network-state"
mkdir -p "$STATE_DIR"

STATUS=""
LAST_STATUS=""

update() {
    if [[ -f "$STATE_FILE" ]]; then
        local ip
        ip=$(ip -4 -o addr show scope global 2>/dev/null \
            | awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }' || true)
        if [[ -z "$ip" ]]; then
            STATUS="󰤭 Disconnected"
        else
            STATUS="󰤨 $ip"
        fi
    else
        local ssid
        ssid=$(iwgetid -r 2>/dev/null || true)
        if [[ -z "$ssid" ]]; then
            STATUS="󰤭 Disconnected"
        else
            STATUS="󰤨 $ssid"
        fi
    fi
}

refresh_if_changed() {
    update
    if [[ "$STATUS" != "$LAST_STATUS" ]]; then
        printf '%s\n' "$STATUS"
        LAST_STATUS="$STATUS"
    fi
}

trap refresh_if_changed USR1

# Emit initial status
refresh_if_changed

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
            refresh_if_changed
            ;;
    esac
done

wait "$NM_PID" 2>/dev/null || true
