#!/usr/bin/env bash
# ── wallpaper-next.sh ─────────────────────────────────────────────────────────
# Pick a new random wallpaper immediately and reset rotation timer.

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/wallpaper-dir"
readonly DEFAULT_DIR="${HOME}/Pictures/walls-catppuccin-mocha"
readonly LOCK_FILE="/tmp/.wallpaper-current"

get_wall_dir() {
    local dir="$DEFAULT_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        local cfg
        cfg=$(tr -d '\n' < "$CONFIG_FILE" 2>/dev/null || true)
        [[ -d "$cfg" ]] && dir="$cfg"
    fi
    echo "$dir"
}

wallpaper_dir=$(get_wall_dir)
current=$(cat "$LOCK_FILE" 2>/dev/null || true)

mapfile -t walls < <(
    find -L "$wallpaper_dir" -maxdepth 3 -type f \
         \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) 2>/dev/null | sort
)
count=${#walls[@]}

if [[ "$count" -eq 0 ]]; then
    echo "No wallpapers found in $wallpaper_dir" >&2
    exit 1
fi

if [[ "$count" -gt 1 ]]; then
    wall=$(printf '%s\n' "${walls[@]}" | grep -Fxv "$current" | shuf -n 1 || true)
    [[ -z "$wall" ]] && wall="${walls[0]}"
else
    wall="${walls[0]}"
fi

echo "$wall" > "$LOCK_FILE"
feh --bg-fill "$wall"

# Reset systemd rotation timer
systemctl --user restart wallpaper-rotate.service 2>/dev/null || true
