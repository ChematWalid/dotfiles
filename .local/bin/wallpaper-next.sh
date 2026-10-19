#!/usr/bin/env bash
# ── wallpaper-next.sh ─────────────────────────────────────────────────────────
# Pick a new random wallpaper immediately and reset rotation timer.

set -euo pipefail

readonly CONFIG_FILE="${HOME}/.config/wallpaper-dir"
readonly DEFAULT_DIR="${HOME}/Pictures/walls-catppuccin-mocha"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-${HOME}/.cache/dotfiles}"
readonly STATE_FILE="${RUNTIME_DIR}/wallpaper-current"
mkdir -p "$RUNTIME_DIR"

get_wall_dir() {
    local dir="$DEFAULT_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        local cfg
        cfg=$(<"$CONFIG_FILE")
        if [[ -d "$cfg" ]]; then
            dir="$cfg"
        else
            printf 'wallpaper-next: configured directory is unavailable: %s\n' "$cfg" >&2
        fi
    fi
    echo "$dir"
}

wallpaper_dir=$(get_wall_dir)
current=""
if [[ -r "$STATE_FILE" ]]; then
    IFS= read -r current < "$STATE_FILE" || true
fi

mapfile -d '' -t walls < <(
    find -L "$wallpaper_dir" -maxdepth 3 -type f \
         \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) \
         -print0
)
count=${#walls[@]}

if [[ "$count" -eq 0 ]]; then
    echo "No wallpapers found in $wallpaper_dir" >&2
    exit 1
fi

if [[ "$count" -gt 1 ]]; then
    current_index=-1
    for ((i = 0; i < count; i++)); do
        if [[ "${walls[$i]}" == "$current" ]]; then
            current_index=$i
            break
        fi
    done

    choice_count=$count
    if (( current_index >= 0 )); then
        choice_count=$((choice_count - 1))
    fi
    selected_index=$(shuf -i "0-$((choice_count - 1))" -n 1)
    if (( current_index >= 0 && selected_index >= current_index )); then
        selected_index=$((selected_index + 1))
    fi
    wall="${walls[$selected_index]}"
else
    wall="${walls[0]}"
fi

feh --bg-fill "$wall"
printf '%s\n' "$wall" > "$STATE_FILE"

# Reset systemd rotation timer
systemctl --user restart wallpaper-rotate.service
