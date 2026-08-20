#!/bin/bash
# Called by dunst on left-click with $APP_NAME set by dunst
# Finds the window belonging to the app and switches i3 to its workspace

APP="$APP_NAME"

# Map common app names to their WM_CLASS (xdotool uses WM_CLASS)
declare -A APP_CLASS_MAP
APP_CLASS_MAP["Telegram Desktop"]="TelegramDesktop"
APP_CLASS_MAP["telegram-desktop"]="TelegramDesktop"
APP_CLASS_MAP["Spotify"]="Spotify"
APP_CLASS_MAP["Google Chrome"]="Google-chrome"
APP_CLASS_MAP["google-chrome"]="Google-chrome"
APP_CLASS_MAP["Chromium"]="Chromium"
APP_CLASS_MAP["Firefox"]="firefox"
APP_CLASS_MAP["discord"]="discord"
APP_CLASS_MAP["Discord"]="discord"
APP_CLASS_MAP["VLC"]="vlc"
APP_CLASS_MAP["Thunar"]="Thunar"

# Look up mapped class or fall back to app name itself
WM_CLASS="${APP_CLASS_MAP[$APP]:-$APP}"

# Find the window ID using xdotool
WIN_ID=$(DISPLAY=:0 xdotool search --classname "$WM_CLASS" 2>/dev/null | head -1)

if [ -n "$WIN_ID" ]; then
    # Get the workspace the window is on and switch to it
    DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
else
    # Fallback: try searching by name
    WIN_ID=$(DISPLAY=:0 xdotool search --name "$APP" 2>/dev/null | head -1)
    if [ -n "$WIN_ID" ]; then
        DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
    fi
fi
