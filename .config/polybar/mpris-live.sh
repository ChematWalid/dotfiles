#!/usr/bin/env bash

update() {
    STATUS=$(playerctl status 2>/dev/null)
    if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
        echo ""
        return
    fi

    if [ "$STATUS" = "Playing" ]; then
        PLAY_ICON="%{F#a6e3a1}󰏥%{F-}"
    else
        PLAY_ICON="%{F#f9e2af}󰐌%{F-}"
    fi

    ARTIST=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
    TITLE=$(playerctl metadata --format '{{title}}' 2>/dev/null)

    if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
        TEXT="$ARTIST - $TITLE"
    elif [ -n "$TITLE" ]; then
        TEXT="$TITLE"
    else
        TEXT="Playing"
    fi

    if [ ${#TEXT} -gt 32 ]; then
        TEXT="${TEXT:0:30}…"
    fi

    PREV="%{F#89b4fa}%{A1:playerctl previous:}󰒮%{A}%{F-}"
    PLAY="%{A1:playerctl play-pause:}${PLAY_ICON}%{A}"
    NEXT="%{F#89b4fa}%{A1:playerctl next:}󰒭%{A}%{F-}"
    NOTE="%{F#f5c2e7}󰎆%{F-}"

    echo "%{T4}${PREV}  ${PLAY}  ${NEXT}%{T-}   ${NOTE} %{F#cdd6f4}${TEXT}%{F-}"
}

# Trap USR1 for instant manual refresh
trap "update" USR1

while true; do
    update
    # playerctl follow blocks and outputs immediately whenever anything changes
    playerctl metadata --format '{{status}}|{{artist}}|{{title}}' --follow 2>/dev/null | while read -r _; do
        update
    done
    sleep 1
done
