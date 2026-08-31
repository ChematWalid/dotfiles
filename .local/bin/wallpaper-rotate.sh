#!/usr/bin/env bash
# wallpaper-rotate.sh — Rotate wallpapers every 30 min
# Managed by systemd wallpaper-rotate.service (no PID file needed)

WALLPAPER_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"
INTERVAL=1800  # 30 min

while true; do
    CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)

    mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)
    COUNT=${#WALLS[@]}

    if [ "$COUNT" -gt 0 ]; then
        if [ "$COUNT" -gt 1 ]; then
            WALL=$(printf '%s\n' "${WALLS[@]}" | grep -Fxv "$CURRENT" | shuf -n 1)
            [ -z "$WALL" ] && WALL="${WALLS[0]}"
        else
            WALL="${WALLS[0]}"
        fi
        echo "$WALL" > "$LOCK_FILE"
        feh --bg-fill "$WALL"
    fi

    sleep "$INTERVAL"
done
