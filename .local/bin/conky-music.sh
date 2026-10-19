#!/usr/bin/env bash
format=$'{{status}}\x1f{{title}}\x1f{{artist}}'
metadata=$(playerctl metadata --format "$format" 2>/dev/null || true)
IFS=$'\x1f' read -r status title artist <<< "$metadata"
title=${title:0:38}
artist=${artist:0:30}

if [ "$status" = "Playing" ]; then
    if [ -n "$artist" ] && [ -n "$title" ]; then
        echo "${title} — ${artist}"
    elif [ -n "$title" ]; then
        echo "${title}"
    fi
elif [ "$status" = "Paused" ]; then
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
