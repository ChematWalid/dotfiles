#!/usr/bin/env bash

STATE_FILE="/tmp/polybar-datetime-state"

update() {
    STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
    case "$STATE" in
        1) # Time only with seconds
            echo "%{F#cba6f7}󰥔%{F-} $(date '+%H:%M:%S')"
            ;;
        2) # Date only
            echo "%{F#89b4fa}󰃭%{F-} $(date '+%a, %d %b %Y')"
            ;;
        *) # Both date and time (State 0 / default)
            echo "%{F#b4befe}󰃰%{F-} $(date '+%d %b %H:%M:%S')"
            ;;
    esac
}

trap "update" USR1

while true; do
    update
    sleep 1 &
    wait $!
done
