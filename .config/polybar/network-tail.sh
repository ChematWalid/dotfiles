#!/bin/bash

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
        SSID=$(iwgetid -r)
        if [ -z "$SSID" ]; then
            echo "󰤭 Disconnected"
        else
            echo "󰤨 $SSID"
        fi
    fi
}

trap "update" USR1

while true; do
    update
    sleep 2 &
    wait $!
done
