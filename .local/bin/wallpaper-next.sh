#!/usr/bin/env bash
# wallpaper-next.sh — Pick a new random wallpaper immediately
# Respects ~/.config/wallpaper-dir (searches 3 folders deep)
# Resets the 30-min rotation timer seamlessly

CONFIG_FILE="$HOME/.config/wallpaper-dir"
DEFAULT_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"

WALLPAPER_DIR="$DEFAULT_DIR"
if [ -f "$CONFIG_FILE" ]; then
    DIR_FROM_CFG=$(cat "$CONFIG_FILE" 2>/dev/null | tr -d '\n')
    [ -d "$DIR_FROM_CFG" ] && WALLPAPER_DIR="$DIR_FROM_CFG"
fi

CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)

# Search up to 3 folders deep for images
mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 3 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort)
COUNT=${#WALLS[@]}

if [ "$COUNT" -eq 0 ]; then
    echo "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

if [ "$COUNT" -gt 1 ]; then
    WALL=$(printf '%s\n' "${WALLS[@]}" | grep -Fxv "$CURRENT" | shuf -n 1)
    [ -z "$WALL" ] && WALL="${WALLS[0]}"
else
    WALL="${WALLS[0]}"
fi

echo "$WALL" > "$LOCK_FILE"
feh --bg-fill "$WALL"

# Update Catppuccin Mocha aesthetic contrast colors for desktop text
~/.local/bin/conky-colors.sh "$WALL" 2>/dev/null || true

# Reset rotation timer
systemctl --user restart wallpaper-rotate.service 2>/dev/null || true
