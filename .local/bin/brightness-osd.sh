#!/usr/bin/env bash
# ── brightness-osd.sh ─────────────────────────────────────────────────────────
# Screen backlight control OSD with Dunst notification bar.

set -euo pipefail

readonly NOTIFICATION_ID=9994
readonly STEP=10
action="${1:-}"

brightness_info=""
backlight_devices=(/sys/class/backlight/*)
if [[ -e "${backlight_devices[0]}" ]]; then
    # Do not let brightnessctl select unrelated LEDs (keyboard, NIC, etc.).
    case "$action" in
        up) brightnessctl --class backlight set "${STEP}%+" >/dev/null 2>&1 || true ;;
        down) brightnessctl --class backlight set "${STEP}%-" >/dev/null 2>&1 || true ;;
    esac
    brightness_info=$(brightnessctl --class backlight -m 2>/dev/null || true)
    if [[ -n "$brightness_info" ]]; then
        IFS=, read -r _ _ _ bright _ <<< "$brightness_info"
        bright="${bright%%%}"
    fi
elif command -v ddcutil >/dev/null 2>&1; then
    # Desktop monitor: use DDC/CI VCP feature 0x10 (brightness).
    case "$action" in
        up) ddcutil --display 1 setvcp 10 + "$STEP" >/dev/null 2>&1 || true ;;
        down) ddcutil --display 1 setvcp 10 - "$STEP" >/dev/null 2>&1 || true ;;
    esac
    brightness_info=$(ddcutil --display 1 getvcp 10 --brief 2>/dev/null || true)
    if [[ -n "$brightness_info" ]]; then
        read -r _ _ _ bright _ <<< "$brightness_info"
    fi
fi

if [[ "${bright:-}" =~ ^[0-9]+$ ]] && command -v dunstify >/dev/null 2>&1; then
    dunstify -a "brightness" \
             -u low \
             -r "$NOTIFICATION_ID" \
             -h string:x-dunst-stack-tag:brightness \
             -h int:value:"$bright" \
             "󰃠  Brightness: ${bright}%" \
             -t 1200 2>/dev/null || true
fi
