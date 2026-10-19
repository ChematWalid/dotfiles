#!/bin/bash

STATE_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
STATE_FILE="${STATE_DIR}/polybar-network-state"
mkdir -p "$STATE_DIR"

if [ "$1" == "toggle" ]; then
    if [ -f "$STATE_FILE" ]; then
        rm "$STATE_FILE"
    else
        touch "$STATE_FILE"
    fi
    exit 0
fi

if [ -f "$STATE_FILE" ]; then
    IP=$(ip -4 -o addr show scope global 2>/dev/null \
        | awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }' || true)
    if [ -z "$IP" ]; then
        echo "󰤭 Disconnected"
    else
        echo "󰤨 $IP"
    fi
else
    SSID=$(iwgetid -r)
    if [ -z "$SSID" ]; then
        echo "󰤭 Disconnected"
    else
        echo "󰤨 $SSID"
    fi
fi
