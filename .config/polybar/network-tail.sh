#!/usr/bin/env bash
# ── network-tail.sh ───────────────────────────────────────────────────────────
# Event-driven network status for Polybar with toggleable SSID / IP view.
# Uses nmcli monitor for zero-polling D-Bus updates and USR1 for instant toggle.

set -euo pipefail

readonly STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
readonly STATE_FILE="${STATE_DIR}/polybar-network-state"
mkdir -p "$STATE_DIR"

if ! command -v nmcli >/dev/null 2>&1; then
    printf 'network-tail: nmcli is not installed or not on PATH\n' >&2
    exit 127
fi

STATUS=""
LAST_STATUS=""

update() {
    if [[ -f "$STATE_FILE" ]]; then
        local ip ip_output
        if ! command -v ip >/dev/null 2>&1; then
            STATUS="󰤮 IP query unavailable"
            printf 'network-tail: ip command is missing\n' >&2
            return
        fi
        if ! ip_output=$(ip -4 -o addr show scope global); then
            STATUS="󰤮 Network query failed"
            printf 'network-tail: could not query global IPv4 addresses\n' >&2
            return
        fi
        ip=$(awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }' <<< "$ip_output")
        if [[ -z "$ip" ]]; then
            STATUS="󰤭 Disconnected"
        else
            STATUS="󰤨 $ip"
        fi
    else
        local ssid
        if ! command -v iwgetid >/dev/null 2>&1; then
            STATUS="󰤮 Wi-Fi status unavailable"
            printf 'network-tail: iwgetid command is missing\n' >&2
            return
        fi
        ssid=$(iwgetid -r || true)
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
coproc NM_MONITOR { exec env LC_ALL=C nmcli monitor; }
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

if wait "$NM_PID"; then
    printf 'network-tail: nmcli monitor exited unexpectedly\n' >&2
else
    monitor_status=$?
    printf 'network-tail: nmcli monitor failed with status %s\n' "$monitor_status" >&2
fi
exit 1
