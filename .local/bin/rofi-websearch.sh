#!/usr/bin/env bash
QUERY=$(echo "" | rofi -dmenu -p "  Search Google" -theme ~/.config/rofi/config.rasi -theme-str 'window {width: 450px; height: 120px;}')
if [ -n "$QUERY" ]; then
    google-chrome "https://www.google.com/search?q=$(echo "$QUERY" | tr ' ' '+')"
fi
