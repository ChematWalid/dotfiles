#!/usr/bin/env bash
# ~/.config/dunst/focus-app-click.sh
# Triggered ONLY when the user clicks a notification in Dunst
# Silently focuses the target application window in i3 without leaking stdout to Dunst

# Ensure no output leaks to stdout/stderr (which Dunst might interpret as a URL)
exec 1>/dev/null 2>/dev/null

APP=$(dunstctl history 2>/dev/null | jq -r '.data[0][0].appname.data // empty' 2>/dev/null)

if [ -z "$APP" ]; then
    exit 0
fi

# Ignore volume / brightness OSD feedback
case "$APP" in
    Volume|volume|Brightness|brightness|"")
        exit 0
        ;;
esac

# Comprehensive regex patterns for i3 class matching
case "$APP" in
    *Telegram*|*telegram*|*AyuGram*|*ayugram*|*64Gram*|*64gram*)
        CLASS_REGEX="(?i)(TelegramDesktop|AyuGramDesktop|AyuGram|64Gram)"
        ;;
    *Spotify*|*spotify*)
        CLASS_REGEX="(?i)Spotify"
        ;;
    *Chrome*|*chrome*|*Chromium*|*chromium*)
        CLASS_REGEX="(?i)(Google-chrome|Chromium)"
        ;;
    *Firefox*|*firefox*)
        CLASS_REGEX="(?i)firefox"
        ;;
    *Brave*|*brave*)
        CLASS_REGEX="(?i)brave-browser"
        ;;
    *Discord*|*discord*|*Vesktop*|*vesktop*|*WebCord*|*webcord*)
        CLASS_REGEX="(?i)(discord|vesktop|webcord)"
        ;;
    *Code*|*code*|*VSCode*|*VSCodium*|*Cursor*|*cursor*)
        CLASS_REGEX="(?i)(Code|Cursor|VSCodium)"
        ;;
    *Kitty*|*kitty*)
        CLASS_REGEX="(?i)kitty"
        ;;
    *Alacritty*|*alacritty*)
        CLASS_REGEX="(?i)Alacritty"
        ;;
    *Thunar*|*thunar*)
        CLASS_REGEX="(?i)Thunar"
        ;;
    *qBittorrent*|*qbittorrent*)
        CLASS_REGEX="(?i)qbittorrent"
        ;;
    *Obsidian*|*obsidian*)
        CLASS_REGEX="(?i)obsidian"
        ;;
    *Slack*|*slack*)
        CLASS_REGEX="(?i)Slack"
        ;;
    *)
        # Default fallback: search by app name directly (case-insensitive)
        CLASS_REGEX="(?i)$APP"
        ;;
esac

# 1. Try focusing directly via i3 class regex
i3-msg "[class=\"$CLASS_REGEX\"] focus" > /dev/null 2>&1

# 2. Fallback: search window tree for partial class or title match
if [ $? -ne 0 ]; then
    CON_ID=$(i3-msg -t get_tree 2>/dev/null | jq -r --arg pat "$APP" '.. | select(.window_properties? != null) | select((.window_properties.class | test($pat; "i")) or (.window_properties.title | test($pat; "i"))) | .id' 2>/dev/null | tail -1)
    if [ -n "$CON_ID" ]; then
        i3-msg "[con_id=$CON_ID] focus" > /dev/null 2>&1
    fi
fi
