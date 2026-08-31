#!/usr/bin/env bash
# ~/.config/dunst/focus-app-click.sh
# Triggered ONLY when the user clicks a notification in Dunst

# 1. Extract appname from the most recent notification in history
APP=$(dunstctl history 2>/dev/null | jq -r '.data[0][0].appname.data // empty' 2>/dev/null)

# Ignore volume / brightness OSD feedback
case "$APP" in
    Volume|volume|Brightness|brightness|"")
        exit 0
        ;;
esac

# 2. Complete mapping of application names to X11 WM_CLASS & window titles
declare -A APP_CLASS_MAP
APP_CLASS_MAP["Telegram Desktop"]="TelegramDesktop"
APP_CLASS_MAP["telegram-desktop"]="TelegramDesktop"
APP_CLASS_MAP["telegram"]="TelegramDesktop"
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
APP_CLASS_MAP["Brave"]="brave-browser"
APP_CLASS_MAP["brave"]="brave-browser"
APP_CLASS_MAP["discord"]="discord"
APP_CLASS_MAP["Discord"]="discord"
APP_CLASS_MAP["Vesktop"]="vesktop"
APP_CLASS_MAP["WebCord"]="webcord"
APP_CLASS_MAP["VLC"]="vlc"
APP_CLASS_MAP["vlc"]="vlc"
APP_CLASS_MAP["Thunar"]="Thunar"
APP_CLASS_MAP["thunar"]="Thunar"
APP_CLASS_MAP["qBittorrent"]="qbittorrent"
APP_CLASS_MAP["qbittorrent"]="qbittorrent"
APP_CLASS_MAP["Code"]="Code"
APP_CLASS_MAP["Visual Studio Code"]="Code"
APP_CLASS_MAP["Cursor"]="Cursor"
APP_CLASS_MAP["kitty"]="kitty"
APP_CLASS_MAP["alacritty"]="Alacritty"
APP_CLASS_MAP["Obsidian"]="obsidian"
APP_CLASS_MAP["Slack"]="Slack"

WM_CLASS="${APP_CLASS_MAP[$APP]:-$APP}"

# 3. Find the matching window
WIN_ID=$(DISPLAY=:0 xdotool search --classname "$WM_CLASS" 2>/dev/null | tail -1)
if [ -z "$WIN_ID" ]; then
    WIN_ID=$(DISPLAY=:0 xdotool search --class "$WM_CLASS" 2>/dev/null | tail -1)
fi
if [ -z "$WIN_ID" ]; then
    WIN_ID=$(DISPLAY=:0 xdotool search --name "$APP" 2>/dev/null | tail -1)
fi

# 4. Focus window in i3 (automatically switches workspace and raises window)
if [ -n "$WIN_ID" ]; then
    DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
fi
