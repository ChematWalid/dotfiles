#!/usr/bin/env bash
# conky-colors.sh — Catppuccin Mocha aesthetic color palette for Conky
# Dynamic contrast based on active wallpaper

WALL="${1:-$(cat /tmp/.wallpaper-current 2>/dev/null)}"
BRIGHTNESS=0.3

if [ -n "$WALL" ] && [ -f "$WALL" ]; then
    BRIGHTNESS=$(magick "$WALL" -gravity center -crop 700x350+0+0 -colorspace Gray -format "%[fx:mean]" info: 2>/dev/null)
    [ -z "$BRIGHTNESS" ] && BRIGHTNESS=0.3
fi

IS_LIGHT=$(echo "$BRIGHTNESS > 0.55" | bc -l 2>/dev/null || echo "0")

if [ "$IS_LIGHT" -eq 1 ]; then
    # Light background -> Rich Catppuccin tones (Peach / Sapphire / Teal) with high readability
    echo "#fab387" > /tmp/conky-color-time.txt     # Catppuccin Peach (warm sand/beige)
    echo "#74c7ec" > /tmp/conky-color-date.txt     # Catppuccin Sapphire
    echo "#a6e3a1" > /tmp/conky-color-music.txt    # Catppuccin Green
    echo "#11111b" > /tmp/conky-color-shade.txt    # Dark shadow for contrast against light
else
    # Dark/Normal background -> Warm Rosewater & Lavender (Catppuccin Mocha aesthetic)
    echo "#f5e0dc" > /tmp/conky-color-time.txt     # Catppuccin Rosewater (warm cream/beige)
    echo "#b4befe" > /tmp/conky-color-date.txt     # Catppuccin Lavender
    echo "#a6e3a1" > /tmp/conky-color-music.txt    # Catppuccin Green
    echo "#11111b" > /tmp/conky-color-shade.txt    # Deep dark shadow
fi
