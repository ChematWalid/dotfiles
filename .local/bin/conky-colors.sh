#!/usr/bin/env bash
# conky-colors.sh — Dynamic inverted/contrast color generator for Conky
# Analyzes center region of active wallpaper to choose light or dark text palette

WALL="${1:-$(cat /tmp/.wallpaper-current 2>/dev/null)}"
[ -z "$WALL" ] || [ ! -f "$WALL" ] && exit 0

# Measure mean luminance (0.0 = pure black, 1.0 = pure white) in center 700x350 box
BRIGHTNESS=$(magick "$WALL" -gravity center -crop 700x350+0+0 -colorspace Gray -format "%[fx:mean]" info: 2>/dev/null)
[ -z "$BRIGHTNESS" ] && BRIGHTNESS=0.2

# If center is bright (> 0.48), use dark text palette. Otherwise use bright Catppuccin palette.
IS_LIGHT=$(echo "$BRIGHTNESS > 0.48" | bc -l 2>/dev/null || echo "0")

if [ "$IS_LIGHT" -eq 1 ]; then
    # Light background -> Crisp dark Catppuccin text
    echo "#11111b" > /tmp/conky-color-time.txt
    echo "#181825" > /tmp/conky-color-date.txt
    echo "#313244" > /tmp/conky-color-music.txt
    echo "#ffffff" > /tmp/conky-color-shade.txt
else
    # Dark background -> Vibrant Catppuccin text
    echo "#cba6f7" > /tmp/conky-color-time.txt
    echo "#89b4fa" > /tmp/conky-color-date.txt
    echo "#a6e3a1" > /tmp/conky-color-music.txt
    echo "#11111b" > /tmp/conky-color-shade.txt
fi
