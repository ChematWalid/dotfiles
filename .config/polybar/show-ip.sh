#!/bin/bash
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)
SSID=$(iwgetid -r || echo "Unknown")
notify-send -t 4000 "Network Information" "<b>SSID:</b> $SSID\n<b>IP Address:</b> $IP"
