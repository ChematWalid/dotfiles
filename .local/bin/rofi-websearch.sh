#!/usr/bin/env bash
# ── rofi-websearch.sh ─────────────────────────────────────────────────────────
# Fast Google search prompt in Rofi with instant Chrome launch.

set -euo pipefail

query=$(
    echo "" | \
    rofi -dmenu \
         -p "  Search Google" \
         -theme "${HOME}/.config/rofi/config.rasi" \
         -theme-str 'window {width: 450px; height: 120px;}' 2>/dev/null || true
)

if [[ -n "$query" ]]; then
    encoded_query=$(jq -rn --arg x "$query" '$x|@uri' 2>/dev/null || echo "$query" | tr ' ' '+')
    google-chrome-stable "https://www.google.com/search?q=${encoded_query}" >/dev/null 2>&1 &
fi
