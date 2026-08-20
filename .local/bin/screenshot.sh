#!/usr/bin/env bash

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date +'%Y%m%d_%H%M%S').png"

notify_success() {
    dunstify -a "screenshot" -u normal -r 9999 -i "$FILE" "📸 Screenshot Captured!" "Copied to clipboard & saved"
}

case "$1" in
    select)
        # Interactive selection
        if maim -s "$FILE"; then
            xclip -selection clipboard -t image/png < "$FILE"
            notify_success
        fi
        ;;
    full)
        # Instant full screen
        maim "$FILE"
        xclip -selection clipboard -t image/png < "$FILE"
        notify_success
        ;;
    window)
        # Active window
        ACTIVE_WIN=$(xdotool getactivewindow)
        maim -i "$ACTIVE_WIN" "$FILE"
        xclip -selection clipboard -t image/png < "$FILE"
        notify_success
        ;;
    delay)
        # Delayed countdown (default 3s)
        SECS=${2:-3}
        for (( i=SECS; i>0; i-- )); do
            dunstify -a "screenshot" -u low -r 9999 "📸 Screenshot in ${i}s..." "Open your menu or dropdown now!"
            sleep 1
        done
        maim "$FILE"
        xclip -selection clipboard -t image/png < "$FILE"
        notify_success
        ;;
    *)
        # Default to selection
        if maim -s "$FILE"; then
            xclip -selection clipboard -t image/png < "$FILE"
            notify_success
        fi
        ;;
esac
