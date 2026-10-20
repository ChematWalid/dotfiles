#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  flameshot-safe.sh — Screenshot launcher for i3/X11.
#  Direct maim capture preserves transient menus and hover previews; use the
#  separate gui mode when you want Flameshot's interactive region selector.
# ══════════════════════════════════════════════════════════════════════════════

set -e

MODE="${1:-gui}"
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="$SAVE_DIR/screenshot_${TIMESTAMP}.png"

# Copies to X11 clipboard and CopyQ clipboard manager
copy_to_clipboards() {
    local file="$1"
    local copied=false
    if command -v xclip >/dev/null 2>&1 \
        && xclip -selection clipboard -t image/png < "$file" 2>/dev/null; then
        copied=true
    fi
    if command -v copyq >/dev/null 2>&1; then
        if copyq write image/png - < "$file" 2>/dev/null; then
            copied=true
        fi
    fi
    [[ "$copied" == true ]]
}

notify_capture() {
    local title="$1"
    local message="$2"
    if copy_to_clipboards "$OUT_FILE"; then
        message+=" & copied to clipboard"
    else
        message+=" (clipboard copy failed)"
    fi
    dunstify -a "screenshot" -u normal -i "$OUT_FILE" "$title" "$message" || true
}

capture_fallback() {
    local title="$1"
    local message="$2"
    if maim -u "$OUT_FILE" 2>/dev/null; then
        notify_capture "$title" "$message"
        return 0
    fi
    dunstify -a "screenshot" -u critical "Screenshot failed" \
        "Could not capture the screen" || true
    return 1
}

# Force the available English translation and use qt6ct for Papirus-Dark icon
# lookup, independent of conflicting session-level portal theme overrides.
# Explicitly disable Qt portal routing to preserve legacy direct X11 capture.
run_flameshot() {
    LC_ALL=en_US.UTF-8 QT_QPA_PLATFORMTHEME=qt6ct QT_USE_PORTAL=0 command flameshot "$@"
}


case "$MODE" in
    overlay)
        # Do not launch a selector or move focus before capture: Telegram
        # previews and other transient windows can disappear when focus changes.
        if maim -u "$OUT_FILE" 2>/dev/null; then
            notify_capture "📸 Screenshot Captured" "Saved to Screenshots"
            if command -v feh >/dev/null 2>&1; then
                feh --auto-zoom --scale-down "$OUT_FILE" >/dev/null 2>&1 &
            fi
        else
            dunstify -a "screenshot" -u critical "Screenshot failed" "Could not capture the screen"
            exit 1
        fi
        ;;

    gui)
        set +e
        run_flameshot gui 2>/dev/null
        FS_EXIT=$?
        set -e
        
        # Exit code 2 means user pressed Escape to cancel — do not take fallback snap
        if [ "$FS_EXIT" -eq 2 ]; then
            exit 0
        fi
        
        # If Flameshot failed with an unexpected error code, fall back to maim
        if [ "$FS_EXIT" -ne 0 ]; then
            capture_fallback "📸 Screenshot Captured" "Direct capture saved to Screenshots" || exit 1
        fi
        ;;

    full)
        set +e
        run_flameshot full -p "$SAVE_DIR" -c 2>/dev/null
        FS_EXIT=$?
        set -e
        if [ "$FS_EXIT" -ne 0 ]; then
            capture_fallback "📸 Fullscreen Captured" "Saved to Screenshots" || exit 1
        fi
        ;;

    screen)
        set +e
        run_flameshot screen -p "$SAVE_DIR" -c 2>/dev/null
        FS_EXIT=$?
        set -e
        if [ "$FS_EXIT" -ne 0 ]; then
            capture_fallback "📸 Screen Captured" "Saved to Screenshots" || exit 1
        fi
        ;;

    delay)
        SECS="${2:-3}"
        if ! [[ "$SECS" =~ ^[0-9]+$ ]]; then
            dunstify -a "screenshot" -u critical "Screenshot failed" "Delay must be a whole number of seconds"
            exit 2
        fi

        # Capture the root window directly after waiting. Starting Flameshot's
        # selector first can dismiss transient menus and hover previews.
        if maim -u -d "$SECS" "$OUT_FILE" 2>/dev/null; then
            notify_capture "📸 Screenshot Captured" "Saved to Screenshots"
            if command -v feh >/dev/null 2>&1; then
                feh --auto-zoom --scale-down "$OUT_FILE" >/dev/null 2>&1 &
            fi
        else
            dunstify -a "screenshot" -u critical "Screenshot failed" "Could not capture the screen"
            exit 1
        fi
        ;;

    *)
        set +e
        run_flameshot gui 2>/dev/null
        FS_EXIT=$?
        set -e
        if [ "$FS_EXIT" -ne 0 ] && [ "$FS_EXIT" -ne 2 ]; then
            capture_fallback "📸 Screenshot Captured" "Direct capture saved to Screenshots" || exit 1
        fi
        ;;
esac
