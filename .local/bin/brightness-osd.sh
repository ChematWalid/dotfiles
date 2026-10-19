#!/usr/bin/env bash
# ── brightness-osd.sh ─────────────────────────────────────────────────────────
# Screen backlight control OSD with Dunst notification bar.

set -euo pipefail

readonly NOTIFICATION_ID=9994
readonly STEP=10
action="${1:-}"
action_failed=false

case "$action" in
    ''|up|down) ;;
    *)
        printf 'Usage: %s [up|down]\n' "${0##*/}" >&2
        exit 2
        ;;
esac

report_error() {
    printf '%s\n' "$1" >&2
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a "Brightness" -u critical -r "$NOTIFICATION_ID" "$1" \
            -t 3000 2>/dev/null || true
    fi
}

brightness_info=""
backlight_devices=(/sys/class/backlight/*)
if [[ -e "${backlight_devices[0]}" ]]; then
    if ! command -v brightnessctl >/dev/null 2>&1; then
        report_error 'Brightness control requires brightnessctl, but it is not installed.'
        exit 1
    fi
    # Do not let brightnessctl select unrelated LEDs (keyboard, NIC, etc.).
    case "$action" in
        up)
            if ! brightnessctl --class backlight set "${STEP}%+" >/dev/null; then
                action_failed=true
            fi
            ;;
        down)
            if ! brightnessctl --class backlight set "${STEP}%-" >/dev/null; then
                action_failed=true
            fi
            ;;
    esac
    if ! brightness_info=$(brightnessctl --class backlight -m); then
        report_error 'Could not read the current backlight brightness.'
        exit 1
    fi
    # brightnessctl machine format: device,class,current,percent,max.
    IFS=, read -r _ _ _ bright _ <<< "$brightness_info"
    bright="${bright%%%}"
elif command -v ddcutil >/dev/null 2>&1; then
    # Desktop monitor: use DDC/CI VCP feature 0x10 (brightness).
    case "$action" in
        up)
            if ! ddcutil --display 1 setvcp 10 + "$STEP" >/dev/null; then
                action_failed=true
            fi
            ;;
        down)
            if ! ddcutil --display 1 setvcp 10 - "$STEP" >/dev/null; then
                action_failed=true
            fi
            ;;
    esac
    if ! brightness_info=$(ddcutil --display 1 getvcp 10 --brief 2>/dev/null); then
        report_error 'Could not read DDC/CI monitor brightness.'
        exit 1
    fi
    read -r _ _ _ bright _ <<< "$brightness_info"
else
    report_error 'No backlight device or DDC/CI brightness control is available.'
    exit 1
fi

if [[ ! "${bright:-}" =~ ^[0-9]+$ ]]; then
    report_error "Unexpected brightness value: ${bright:-empty}"
    exit 1
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

if [[ "$action_failed" == true ]]; then
    report_error 'The brightness change failed; showing the current value.'
    exit 1
fi
