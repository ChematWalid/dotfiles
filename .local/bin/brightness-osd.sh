#!/usr/bin/env bash
# ── brightness-osd.sh ─────────────────────────────────────────────────────────
# Screen backlight control OSD with Dunst notification bar.

set -euo pipefail

readonly NOTIFICATION_ID=9994
action="${1:-}"

case "$action" in
    up)
        brightnessctl set 10%+ >/dev/null 2>&1 || true
        ;;
    down)
        brightnessctl set 10%- >/dev/null 2>&1 || true
        ;;
esac

# Extract current brightness percentage
bright=$(brightnessctl 2>/dev/null | grep -Po '[0-9]+(?=%)' | head -1 || echo "50")

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "brightness" \
             -u low \
             -r "$NOTIFICATION_ID" \
             -h string:x-dunst-stack-tag:brightness \
             -h int:value:"$bright" \
             "󰃠  Brightness: ${bright}%" \
             -t 1200 2>/dev/null || true
fi
