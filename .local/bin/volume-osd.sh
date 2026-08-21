#!/usr/bin/env bash
# Volume OSD with Dunst notification bar

STEP=5
NOTIFICATION_ID=2593

case "$1" in
    up)
        pamixer -u
        pamixer -i "$STEP"
        ;;
    down)
        pamixer -u
        pamixer -d "$STEP"
        ;;
    mute)
        pamixer -t
        ;;
    mic-mute)
        pamixer --default-source -t
        ;;
esac

MUTED=$(pamixer --get-mute 2>/dev/null || echo "false")
VOL=$(pamixer --get-volume 2>/dev/null || echo "50")

if [ "$MUTED" = "true" ] || [ "$VOL" -eq 0 ]; then
    ICON="audio-volume-muted"
    TEXT="Muted"
    VOL=0
else
    if [ "$VOL" -ge 70 ]; then
        ICON="audio-volume-high"
    elif [ "$VOL" -ge 30 ]; then
        ICON="audio-volume-medium"
    else
        ICON="audio-volume-low"
    fi
    TEXT="${VOL}%"
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Volume" -r "$NOTIFICATION_ID" -u low -i "$ICON" -h int:value:"$VOL" "Volume: $TEXT" -t 1200
fi
