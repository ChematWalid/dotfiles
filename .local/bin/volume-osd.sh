#!/usr/bin/env bash
# ── volume-osd.sh ─────────────────────────────────────────────────────────────
# Volume control OSD with Dunst notification bar and synchronous audio feedback.

set -euo pipefail

readonly STEP=1
readonly NOTIFICATION_ID=2593

action="${1:-}"

case "$action" in
    up)
        pamixer -u >/dev/null 2>&1 || true
        pamixer --allow-boost -i "$STEP" >/dev/null 2>&1 || true
        ;;
    down)
        pamixer -u >/dev/null 2>&1 || true
        pamixer -d "$STEP" >/dev/null 2>&1 || true
        ;;
    mute)
        pamixer -t >/dev/null 2>&1 || true
        ;;
    mic-mute)
        pamixer --default-source -t >/dev/null 2>&1 || true
        ;;
esac

volume_state=$(pamixer --get-volume-human 2>/dev/null || echo "50%")
if [[ "$volume_state" == "muted" ]]; then
    muted=true
    vol=0
else
    muted=false
    vol="${volume_state%%%}"
    [[ "$vol" =~ ^[0-9]+$ ]] || vol=50
fi

if [[ "$muted" == "true" ]] || [[ "$vol" -eq 0 ]]; then
    icon="audio-volume-muted"
    text="Muted"
    vol=0
else
    if [[ "$vol" -ge 70 ]]; then
        icon="audio-volume-high"
    elif [[ "$vol" -ge 30 ]]; then
        icon="audio-volume-medium"
    else
        icon="audio-volume-low"
    fi
    text="${vol}%"
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Volume" \
             -r "$NOTIFICATION_ID" \
             -u low \
             -i "$icon" \
             -h int:value:"$vol" \
             "Volume: ${text}" \
             -t 1200 2>/dev/null || true
fi
