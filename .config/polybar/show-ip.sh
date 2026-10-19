#!/usr/bin/env bash
# ── show-ip.sh ────────────────────────────────────────────────────────────────
# Displays network connection details via desktop notification.

set -euo pipefail

ip=$(ip -4 -o addr show scope global 2>/dev/null \
    | awk 'NR == 1 { sub(/\/.*/, "", $4); print $4; exit }' || true)
ip=${ip:-None}
ssid=$(iwgetid -r 2>/dev/null || echo "Disconnected / Wired")

notify-send -t 4000 \
            -i network-wireless \
            "Network Information" \
            "<b>SSID:</b> ${ssid}\n<b>IP Address:</b> ${ip}" 2>/dev/null || true
