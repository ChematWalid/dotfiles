#!/usr/bin/env bash
# ── rofi-websearch.sh ─────────────────────────────────────────────────────────
# Fast Google search prompt in Rofi with instant Firefox launch.

set -euo pipefail

query=$(
    echo "" | \
    rofi -dmenu \
         -p "  Search Google" \
         -theme "${HOME}/.config/rofi/config.rasi" \
         -theme-str 'window {width: 450px; height: 120px;}' 2>/dev/null || true
)

if [[ -n "$query" ]]; then
    browser="${BROWSER:-firefox}"
    if [[ "$browser" == "google-chrome-stable" || "$browser" == "google-chrome" ]]; then
        browser="firefox"
    fi

    if [[ "$query" =~ ^https?:// ]]; then
        "$browser" "$query" >/dev/null 2>&1 &
    elif [[ "$query" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ && ! "$query" =~ [[:space:]] ]]; then
        "$browser" "https://${query}" >/dev/null 2>&1 &
    else
        encoded_query=$(jq -rn --arg x "$query" '$x|@uri' 2>/dev/null || echo "$query" | tr ' ' '+')
        "$browser" "https://www.google.com/search?q=${encoded_query}" >/dev/null 2>&1 &
    fi
fi
