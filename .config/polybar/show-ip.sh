#!/usr/bin/env bash
# ── show-ip.sh ────────────────────────────────────────────────────────────────
# Displays network connection details via desktop notification.

set -euo pipefail

ip_output=$(ip -4 -o addr show scope global 2>/dev/null || true)
read -r -a address_fields <<< "$ip_output"
ip="${address_fields[3]:-}"
ip=${ip%%/*}
ip=${ip:-None}
ssid=$(iwgetid -r 2>/dev/null || echo "Disconnected / Wired")

notify-send -t 4000 \
            -i network-wireless \
            "Network Information" \
            "<b>SSID:</b> ${ssid}\n<b>IP Address:</b> ${ip}" 2>/dev/null || true
