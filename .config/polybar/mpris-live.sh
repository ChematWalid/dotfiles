#!/usr/bin/env bash

update() {
    STATUS=$(playerctl status 2>/dev/null)

    if [ "$STATUS" = "Playing" ]; then
        PLAY_ICON="%{F#a6e3a1}󰏥%{F-}" # Green Pause icon
        ARTIST=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
        TITLE=$(playerctl metadata --format '{{title}}' 2>/dev/null)
    elif [ "$STATUS" = "Paused" ]; then
        PLAY_ICON="%{F#f9e2af}󰐌%{F-}" # Yellow Play icon
        ARTIST=$(playerctl metadata --format '{{artist}}' 2>/dev/null)
        TITLE=$(playerctl metadata --format '{{title}}' 2>/dev/null)
    else
        PLAY_ICON="%{F#6c7086}󰐌%{F-}" # Muted Play icon
        ARTIST=""
        TITLE="No player"
    fi

    if [ -n "$ARTIST" ] && [ -n "$TITLE" ]; then
        TEXT="$ARTIST - $TITLE"
    elif [ -n "$TITLE" ]; then
        TEXT="$TITLE"
    else
        TEXT="Offline"
    fi

    if [ ${#TEXT} -gt 32 ]; then
        TEXT="${TEXT:0:30}…"
    fi

    PREV="%{F#89b4fa}%{A1:playerctl previous 2>/dev/null:}󰒮%{A}%{F-}"
    PLAY="%{A1:playerctl play-pause 2>/dev/null:}${PLAY_ICON}%{A}"
    NEXT="%{F#89b4fa}%{A1:playerctl next 2>/dev/null:}󰒭%{A}%{F-}"
    NOTE="%{F#f5c2e7}󰎆%{F-}"

    if [ -z "$STATUS" ] || [ "$STATUS" = "Stopped" ]; then
        # Click on "No player" opens Spotify
        echo "%{T4}${PREV}  ${PLAY}  ${NEXT}%{T-}   ${NOTE} %{F#6c7086}%{A1:spotify &:}No player%{A}%{F-}"
    else
        echo "%{T4}${PREV}  ${PLAY}  ${NEXT}%{T-}   ${NOTE} %{F#cdd6f4}${TEXT}%{F-}"
    fi
}

# Trap USR1 for instant manual refresh
trap "update" USR1

while true; do
    update
    # Follow playerctl events if a player exists, otherwise poll smoothly
    playerctl metadata --format '{{status}}|{{artist}}|{{title}}' --follow 2>/dev/null | while read -r _; do
        update
    done
    sleep 2
done
