#!/usr/bin/env bash

case "$1" in
    up)
        pactl set-sink-mute @DEFAULT_SINK@ false
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        pactl set-sink-mute @DEFAULT_SINK@ false
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
esac

# Get current volume and mute status
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -Po '[0-9]+(?=%)' | head -1)

if [ "$MUTED" = "yes" ] || [ "$VOL" -eq 0 ]; then
    dunstify -a "volume" -u low -r 9993 -h string:x-dunst-stack-tag:volume -h int:value:0 "󰝟  Muted" "Volume is turned off"
else
    dunstify -a "volume" -u low -r 9993 -h string:x-dunst-stack-tag:volume -h int:value:"$VOL" "󰕾  Volume: ${VOL}%"
fi
