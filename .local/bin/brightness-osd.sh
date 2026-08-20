#!/usr/bin/env bash

case "$1" in
    up)
        brightnessctl set 10%+
        ;;
    down)
        brightnessctl set 10%-
        ;;
esac

# Get current brightness percentage
BRIGHT=$(brightnessctl | grep -Po '[0-9]+(?=%)' | head -1)
dunstify -a "brightness" -u low -r 9994 -h string:x-dunst-stack-tag:brightness -h int:value:"$BRIGHT" "󰃠  Brightness: ${BRIGHT}%"
