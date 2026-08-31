#!/usr/bin/env bash
# wallpaper-rotate.sh — Rotate wallpapers every 30 min
# Respects ~/.config/wallpaper-dir (searches 3 folders deep)
# Managed by systemd wallpaper-rotate.service

CONFIG_FILE="$HOME/.config/wallpaper-dir"
DEFAULT_DIR="$HOME/Pictures/walls-catppuccin-mocha"
LOCK_FILE="/tmp/.wallpaper-current"
INTERVAL=1800  # 30 min

get_wall_dir() {
    local dir="$DEFAULT_DIR"
    if [ -f "$CONFIG_FILE" ]; then
        local cfg
        cfg=$(cat "$CONFIG_FILE" 2>/dev/null | tr -d '\n')
        [ -d "$cfg" ] && dir="$cfg"
    fi
    echo "$dir"
}

WALLPAPER_DIR=$(get_wall_dir)

# On startup, restore last active wallpaper or pick initial
CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)
if [ -n "$CURRENT" ] && [ -f "$CURRENT" ]; then
    feh --bg-fill "$CURRENT"
    ~/.local/bin/conky-colors.sh "$CURRENT" 2>/dev/null || true
else
    mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 3 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort)
    if [ ${#WALLS[@]} -gt 0 ]; then
        WALL=$(printf '%s\n' "${WALLS[@]}" | shuf -n 1)
        echo "$WALL" > "$LOCK_FILE"
        feh --bg-fill "$WALL"
        ~/.local/bin/conky-colors.sh "$WALL" 2>/dev/null || true
    fi
fi

# Rotate every 30 minutes
while true; do
    sleep "$INTERVAL"

    WALLPAPER_DIR=$(get_wall_dir)
    CURRENT=$(cat "$LOCK_FILE" 2>/dev/null)
    mapfile -t WALLS < <(find -L "$WALLPAPER_DIR" -maxdepth 3 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort)
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
