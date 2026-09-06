#!/usr/bin/env bash
# network-tail.sh — Event-driven network status for Polybar
# Uses nmcli monitor (NetworkManager D-Bus events) — zero polling

STATE_FILE="/tmp/polybar-network-state"

update() {
    if [ -f "$STATE_FILE" ]; then
        IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
        if [ -z "$IP" ]; then
            echo "󰤭 Disconnected"
        else
            echo "󰤨 $IP"
        fi
    else
        SSID=$(iwgetid -r 2>/dev/null)
        if [ -z "$SSID" ]; then
            echo "󰤭 Disconnected"
        else
            echo "󰤨 $SSID"
        fi
    fi
}

# Emit initial state
update

# Stream NetworkManager events — fires instantly on connect/disconnect/IP change
nmcli monitor 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"connected"*|*"disconnected"*|*"connecting"*|*"activated"*|*"deactivated"*)
            update
            ;;
    esac
done

# Fallback if nmcli exits unexpectedly
while true; do
    update
    sleep 5
done
