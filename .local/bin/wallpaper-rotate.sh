#!/usr/bin/env bash
# wallpaper-rotate.sh — Rotate through Catppuccin walls every 30 min
# Uses /tmp/.wallpaper-current to avoid immediate repeats

PIDFILE="/tmp/.wallpaper-rotate.pid"
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
    fi
fi
echo "$$" > "$PIDFILE"

WALLPAPER_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"
INTERVAL=1800  # 30 min — change to e.g. 300 for 5 min

while true; do
    CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)
    mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)
    COUNT=${#WALLS[@]}

    if [ "$COUNT" -gt 0 ]; then
        if [ "$COUNT" -gt 1 ]; then
            CANDIDATES=()
            for w in "${WALLS[@]}"; do
                [ "$w" != "$CURRENT" ] && CANDIDATES+=("$w")
            done
            WALL="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
        else
            WALL="${WALLS[0]}"
        fi
        echo "$WALL" > "$LOCK_FILE"
        feh --bg-fill "$WALL"
    fi

    sleep "$INTERVAL"
done
