#!/usr/bin/env bash
# wallpaper-next.sh — Pick a new random wallpaper immediately
# Systemd wallpaper-rotate.service handles the timed rotation.
# This script just picks the next wall and signals the service to reset its timer.

WALLPAPER_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"

# Read current wall to avoid repeating
CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)

# Use shuf for uniform random distribution
mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) 2>/dev/null | sort)
COUNT=${#WALLS[@]}

if [ "$COUNT" -eq 0 ]; then exit 1; fi

if [ "$COUNT" -gt 1 ]; then
    WALL=$(printf '%s\n' "${WALLS[@]}" | grep -Fxv "$CURRENT" | shuf -n 1)
    [ -z "$WALL" ] && WALL="${WALLS[0]}"
else
    WALL="${WALLS[0]}"
fi

echo "$WALL" > "$LOCK_FILE"
feh --bg-fill "$WALL"

# Update text contrast colors for Conky based on new wallpaper brightness
~/.local/bin/conky-colors.sh "$WALL" 2>/dev/null || true

# Restart the service to reset the 30-minute timer without triggering another change
systemctl --user restart wallpaper-rotate.service 2>/dev/null || true
