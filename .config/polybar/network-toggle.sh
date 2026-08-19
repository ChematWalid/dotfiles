#!/bin/bash

STATE_FILE="/tmp/polybar-network-state"

if [ "$1" == "toggle" ]; then
    if [ -f "$STATE_FILE" ]; then
        rm "$STATE_FILE"
    else
        touch "$STATE_FILE"
    fi
    exit 0
fi

if [ -f "$STATE_FILE" ]; then
    IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
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
