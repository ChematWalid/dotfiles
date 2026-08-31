#!/usr/bin/env bash
# ~/.config/dunst/focus-app.sh
# Executed ONLY when the user clicks a notification (always_run_script = false)
# Dispatches focus via i3 / xdotool to the corresponding application window

APP="${APP_NAME:-$1}"
SUMMARY="$2"
BODY="$3"
ACTION="$6"

# Ignore OSD feedback
case "$APP" in
    Volume|volume|Brightness|brightness|"")
        exit 0
        ;;
esac

# Map notification appname to X11 WM_CLASS and process names
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

# 1. Search by exact window class
WIN_ID=$(DISPLAY=:0 xdotool search --classname "$WM_CLASS" 2>/dev/null | tail -1)

# 2. Fallback: search by case-insensitive class / name
if [ -z "$WIN_ID" ]; then
    WIN_ID=$(DISPLAY=:0 xdotool search --class "$WM_CLASS" 2>/dev/null | tail -1)
fi
if [ -z "$WIN_ID" ]; then
    WIN_ID=$(DISPLAY=:0 xdotool search --name "$APP" 2>/dev/null | tail -1)
fi

# 3. If window found, focus it via i3
if [ -n "$WIN_ID" ]; then
    DISPLAY=:0 i3-msg "[id=$WIN_ID] focus"
fi
