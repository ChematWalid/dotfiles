#!/usr/bin/env bash
# Instant Catppuccin Blurred Lockscreen
LOCK_IMG="$HOME/.cache/lockscreen.png"
if [ ! -f "$LOCK_IMG" ]; then
    magick /home/walid/Downloads/catppuccin-wall-dark.jpg -scale 1366x768^ -gravity center -extent 1366x768 -blur 0x10 "$LOCK_IMG"
fi

i3lock -i "$LOCK_IMG" -c 1e1e2e --nofork
