#!/usr/bin/env bash
# Real-time event-driven music listener for Conky using playerctl DBus events
OUTPUT_FILE="/tmp/conky-music.txt"

update_music() {
    local status title artist mpc_track
    status=$(playerctl status 2>/dev/null)

    if [ "$status" = "Playing" ]; then
        title=$(playerctl metadata title 2>/dev/null | cut -c1-38)
        artist=$(playerctl metadata artist 2>/dev/null | cut -c1-30)
        if [ -n "$artist" ] && [ -n "$title" ]; then
            echo "${title} — ${artist}" > "$OUTPUT_FILE"
        elif [ -n "$title" ]; then
            echo "${title}" > "$OUTPUT_FILE"
        else
            echo "" > "$OUTPUT_FILE"
        fi
    elif [ "$status" = "Paused" ]; then
        title=$(playerctl metadata title 2>/dev/null | cut -c1-38)
        artist=$(playerctl metadata artist 2>/dev/null | cut -c1-30)
        if [ -n "$artist" ] && [ -n "$title" ]; then
            echo "[Paused] ${title} — ${artist}" > "$OUTPUT_FILE"
        elif [ -n "$title" ]; then
            echo "[Paused] ${title}" > "$OUTPUT_FILE"
        else
            echo "" > "$OUTPUT_FILE"
        fi
    else
        mpc_track=$(mpc current 2>/dev/null)
        if [ -n "$mpc_track" ]; then
            echo "${mpc_track}" > "$OUTPUT_FILE"
        else
            echo "" > "$OUTPUT_FILE"
        fi
    fi
}

# Initial update
update_music

# Listen for DBus MPRIS playback events in real-time
playerctl metadata --follow --format '{{status}}:{{artist}}:{{title}}' 2>/dev/null | while read -r line; do
    update_music
done
