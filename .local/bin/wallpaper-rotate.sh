#!/usr/bin/env bash
# ── wallpaper-rotate.sh ───────────────────────────────────────────────────────
# Rotate wallpapers automatically every 30 minutes.
# Managed by systemd wallpaper-rotate.service.

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/wallpaper-dir"
readonly DEFAULT_DIR="${HOME}/Pictures/walls-catppuccin-mocha"
readonly LOCK_FILE="/tmp/.wallpaper-current"
readonly INTERVAL=1800 # 30 min

get_wall_dir() {
    local dir="$DEFAULT_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        local cfg
        cfg=$(tr -d '\n' < "$CONFIG_FILE" 2>/dev/null || true)
        [[ -d "$cfg" ]] && dir="$cfg"
    fi
    echo "$dir"
}

pick_and_apply_wallpaper() {
    local wallpaper_dir
    wallpaper_dir=$(get_wall_dir)
    local current
    current=$(cat "$LOCK_FILE" 2>/dev/null || true)

    local walls=()
    mapfile -t walls < <(
        find -L "$wallpaper_dir" -maxdepth 3 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort
    )
    local count=${#walls[@]}

    if [[ "$count" -gt 0 ]]; then
        local wall
        if [[ "$count" -gt 1 ]]; then
            wall=$(printf '%s\n' "${walls[@]}" | grep -Fxv "$current" | shuf -n 1 || true)
            [[ -z "$wall" ]] && wall="${walls[0]}"
        else
            wall="${walls[0]}"
        fi
        echo "$wall" > "$LOCK_FILE"
        feh --bg-fill "$wall"
        pkill -SIGUSR1 conky 2>/dev/null || true
    fi
}

# Initial restoration or random pick on service start
current_wall=$(cat "$LOCK_FILE" 2>/dev/null || true)
if [[ -n "$current_wall" && -f "$current_wall" ]]; then
    feh --bg-fill "$current_wall"
else
    pick_and_apply_wallpaper
fi

# Main rotation loop
while true; do
    sleep "$INTERVAL"
    pick_and_apply_wallpaper
done
