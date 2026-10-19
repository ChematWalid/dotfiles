#!/usr/bin/env bash
# ── wallpaper-rotate.sh ───────────────────────────────────────────────────────
# Rotate wallpapers automatically every 30 minutes.
# Managed by systemd wallpaper-rotate.service.

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/wallpaper-dir"
readonly DEFAULT_DIR="${HOME}/Pictures/walls-catppuccin-mocha"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache/dotfiles}"
readonly STATE_FILE="${RUNTIME_DIR}/wallpaper-current"
readonly INTERVAL=1800 # 30 min
mkdir -p "$RUNTIME_DIR"

get_wall_dir() {
    local dir="$DEFAULT_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        local cfg
        cfg=$(<"$CONFIG_FILE")
        [[ -d "$cfg" ]] && dir="$cfg"
    fi
    echo "$dir"
}

pick_and_apply_wallpaper() {
    local wallpaper_dir
    wallpaper_dir=$(get_wall_dir)
    local current=""
    if [[ -r "$STATE_FILE" ]]; then
        IFS= read -r current < "$STATE_FILE" || true
    fi

    local walls=()
    mapfile -t walls < <(
        find -L "$wallpaper_dir" -maxdepth 3 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null
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
        echo "$wall" > "$STATE_FILE"
        feh --bg-fill "$wall"
    fi
}

# Initial restoration or random pick on service start
current_wall=""
if [[ -r "$STATE_FILE" ]]; then
    IFS= read -r current_wall < "$STATE_FILE" || true
fi
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
