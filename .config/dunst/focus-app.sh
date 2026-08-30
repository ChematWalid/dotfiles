#!/bin/bash
# Called by dunst on notification click / action
# Dispatches focus via i3 to the target window

APP="${APP_NAME:-$1}"

# Ignore OSD / transient feedback
case "$APP" in
    Volume|volume|Brightness|brightness|"")
        exit 0
        ;;
esac

# Map application names to their X11 WM_CLASS
declare -A APP_CLASS_MAP
APP_CLASS_MAP["Telegram Desktop"]="TelegramDesktop"
APP_CLASS_MAP["telegram-desktop"]="TelegramDesktop"
APP_CLASS_MAP["AyuGram"]="AyuGram"
APP_CLASS_MAP["AyuGram Desktop"]="AyuGram"
APP_CLASS_MAP["64Gram"]="TelegramDesktop"
APP_CLASS_MAP["64Gram Desktop"]="TelegramDesktop"
APP_CLASS_MAP["Spotify"]="Spotify"
APP_CLASS_MAP["spotify"]="Spotify"
APP_CLASS_MAP["Google Chrome"]="Google-chrome"
APP_CLASS_MAP["google-chrome"]="Google-chrome"
APP_CLASS_MAP["Chromium"]="Chromium"
APP_CLASS_MAP["chromium"]="Chromium"
APP_CLASS_MAP["Firefox"]="firefox"
APP_CLASS_MAP["firefox"]="firefox"
APP_CLASS_MAP["discord"]="discord"
APP_CLASS_MAP["Discord"]="discord"
APP_CLASS_MAP["VLC"]="vlc"
APP_CLASS_MAP["vlc"]="vlc"
APP_CLASS_MAP["Thunar"]="Thunar"
APP_CLASS_MAP["thunar"]="Thunar"
APP_CLASS_MAP["qBittorrent"]="qbittorrent"
APP_CLASS_MAP["qbittorrent"]="qbittorrent"
APP_CLASS_MAP["Code"]="Code"
APP_CLASS_MAP["Visual Studio Code"]="Code"
APP_CLASS_MAP["kitty"]="kitty"
APP_CLASS_MAP["alacritty"]="Alacritty"

WM_CLASS="${APP_CLASS_MAP[$APP]:-$APP}"

# Search by window class first
WIN_ID=$(DISPLAY=:0 xdotool search --classname "$WM_CLASS" 2>/dev/null | head -1)

if [ -n "$WIN_ID" ]; then
    DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
else
    # Fallback to search by window title/name
    WIN_ID=$(DISPLAY=:0 xdotool search --name "$APP" 2>/dev/null | head -1)
    if [ -n "$WIN_ID" ]; then
        DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
    fi
fi
