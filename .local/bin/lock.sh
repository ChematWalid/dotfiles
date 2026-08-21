#!/usr/bin/env bash
# Fast aesthetic lockscreen using blurred Catppuccin wallpaper
LOCK_BG="$HOME/.cache/lockscreen.png"
WALLPAPER="$HOME/Downloads/catppuccin-wall-dark.jpg"

if [ ! -f "$LOCK_BG" ] && [ -f "$WALLPAPER" ]; then
    magick "$WALLPAPER" -scale 10% -scale 1000% -fill "#1e1e2e" -colorize 30% "$LOCK_BG" 2>/dev/null || true
fi

if [ -f "$LOCK_BG" ]; then
    i3lock -n -i "$LOCK_BG" -t
else
    i3lock -n -c 1e1e2e
fi
