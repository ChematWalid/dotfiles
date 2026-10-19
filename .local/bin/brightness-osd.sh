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

# Machine-readable output includes the current percentage directly, avoiding
# the grep and head processes previously used to parse brightnessctl's text.
bright="50"
if brightness_info=$(brightnessctl -m 2>/dev/null); then
    IFS=, read -r _ _ _ bright _ <<< "$brightness_info"
    bright="${bright%%%}"
    [[ "$bright" =~ ^[0-9]+$ ]] || bright="50"
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "brightness" \
             -u low \
             -r "$NOTIFICATION_ID" \
             -h string:x-dunst-stack-tag:brightness \
             -h int:value:"$bright" \
             "󰃠  Brightness: ${bright}%" \
             -t 1200 2>/dev/null || true
fi
