#!/usr/bin/env bash
status=$(playerctl status 2>/dev/null)

if [ "$status" = "Playing" ]; then
    title=$(playerctl metadata title 2>/dev/null | cut -c1-38)
    artist=$(playerctl metadata artist 2>/dev/null | cut -c1-30)
    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "${title} — ${artist}"
    elif [ -n "$title" ]; then
        echo "${title}"
    fi
elif [ "$status" = "Paused" ]; then
    title=$(playerctl metadata title 2>/dev/null | cut -c1-38)
    artist=$(playerctl metadata artist 2>/dev/null | cut -c1-30)
    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "[Paused] ${title} — ${artist}"
    elif [ -n "$title" ]; then
        echo "[Paused] ${title}"
    fi
else
    mpc_track=$(mpc current 2>/dev/null)
    if [ -n "$mpc_track" ]; then
        echo "${mpc_track}"
    fi
fi
