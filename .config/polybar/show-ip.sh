#!/usr/bin/env bash
# ── show-ip.sh ────────────────────────────────────────────────────────────────
# Displays network connection details via desktop notification.

set -euo pipefail

route=$(ip -4 route get 1.1.1.1 2>/dev/null | head -n 1 || true)
ip=$(awk '{for (i = 1; i <= NF; i++) if ($i == "src") {print $(i + 1); exit}}' <<< "$route")
interface=$(awk '{for (i = 1; i <= NF; i++) if ($i == "dev") {print $(i + 1); exit}}' <<< "$route")
ip=${ip:-None}

ssid=$(iwgetid -r 2>/dev/null || true)
if [[ -z "$ssid" && -n "$interface" ]]; then
    ssid=$(nmcli -g GENERAL.CONNECTION device show "$interface" 2>/dev/null || true)
fi
ssid=${ssid:-Disconnected / Wired}

printf -v message 'SSID: %s\nIP Address: %s' "$ssid" "$ip"
notify-send -t 4000 -i network-wireless "Network Information" "$message" 2>/dev/null || true
