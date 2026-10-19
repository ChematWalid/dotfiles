#!/usr/bin/env bash
# Real-time event-driven music listener for Conky using playerctl DBus events
OUTPUT_FILE="${XDG_RUNTIME_DIR:-$HOME/.cache}/conky-music.txt"
mkdir -p "$(dirname "$OUTPUT_FILE")"

update_music() {
    local status="${1:-}" title="${2:-}" artist="${3:-}" mpc_track prefix=""
    title=${title:0:38}
    artist=${artist:0:30}

    if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
        [ "$status" = "Paused" ] && prefix="[Paused] "
        if [ -n "$artist" ] && [ -n "$title" ]; then
            printf '%s%s — %s\n' "$prefix" "$title" "$artist" > "$OUTPUT_FILE"
        elif [ -n "$title" ]; then
            printf '%s%s\n' "$prefix" "$title" > "$OUTPUT_FILE"
        else
            : > "$OUTPUT_FILE"
        fi
    else
        mpc_track=$(mpc current 2>/dev/null)
        if [ -n "$mpc_track" ]; then
            printf '%s\n' "$mpc_track" > "$OUTPUT_FILE"
        else
            : > "$OUTPUT_FILE"
        fi
    fi
}

readonly FORMAT=$'{{status}}\x1f{{title}}\x1f{{artist}}'

# Initial update, then keep one playerctl event stream instead of spawning
# separate status/title/artist queries for every metadata change.
initial=$(playerctl metadata --format "$FORMAT" 2>/dev/null || true)
IFS=$'\x1f' read -r status title artist <<< "$initial"
update_music "$status" "$title" "$artist"

# Listen for DBus MPRIS playback events in real-time
playerctl metadata --follow --format "$FORMAT" 2>/dev/null | while IFS=$'\x1f' read -r status title artist; do
    update_music "$status" "$title" "$artist"
done
