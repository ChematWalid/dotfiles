#!/usr/bin/env bash
# ── show-ip.sh ────────────────────────────────────────────────────────────────
# Displays network connection details via desktop notification.

set -euo pipefail

ip=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1 || echo "None")
ssid=$(iwgetid -r 2>/dev/null || echo "Disconnected / Wired")

notify-send -t 4000 \
            -i network-wireless \
            "Network Information" \
            "<b>SSID:</b> ${ssid}\n<b>IP Address:</b> ${ip}" 2>/dev/null || true
