#!/usr/bin/env bash
# wallpaper-next.sh — Pick a new random wallpaper immediately
# Called by keybinding — also resets the rotation daemon timer

WALLPAPER_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"
PIDFILE="/tmp/.wallpaper-rotate.pid"

# Read current wall to avoid repeating
CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)

mapfile -t WALLS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)
COUNT=${#WALLS[@]}

if [ "$COUNT" -eq 0 ]; then exit 1; fi

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

# Restart the rotation daemon so the 30-min timer resets from NOW
if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill "$OLD_PID" 2>/dev/null
    fi
fi
nohup "$HOME/.local/bin/wallpaper-rotate.sh" >/dev/null 2>&1 &
