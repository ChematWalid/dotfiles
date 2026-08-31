#!/usr/bin/env bash
# wallpaper-rotate.sh — Rotate wallpapers every 30 min
# Managed by systemd wallpaper-rotate.service

WALLPAPER_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"
INTERVAL=1800  # 30 min

# On startup, ensure the current wallpaper is set if already saved, or pick initial one
CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)
if [ -n "$CURRENT" ] && [ -f "$CURRENT" ]; then
    feh --bg-fill "$CURRENT"
    ~/.local/bin/conky-colors.sh "$CURRENT" 2>/dev/null || true
else
    mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)
    if [ ${#WALLS[@]} -gt 0 ]; then
        WALL=$(printf '%s\n' "${WALLS[@]}" | shuf -n 1)
        echo "$WALL" > "$LOCK_FILE"
        feh --bg-fill "$WALL"
        ~/.local/bin/conky-colors.sh "$WALL" 2>/dev/null || true
    fi
fi

# Then loop: sleep 30 minutes, then rotate
while true; do
    sleep "$INTERVAL"

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
        ~/.local/bin/conky-colors.sh "$WALL" 2>/dev/null || true
    fi
done
