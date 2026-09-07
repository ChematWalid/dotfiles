#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  flameshot-safe.sh — Universal, Zero-Interruption Screenshot Launcher
#  Captures anywhere, anytime:
#   - Detects active X11 grabs (dropdown menus, context menus, popups).
#   - NEVER sends synthetic key events (prevents closing menus/popups).
#   - Seamlessly uses maim for instant, un-interrupted grab capture.
#   - Uses Flameshot GUI for rich interactive annotation when screen is free.
#   - Ignores intentional user aborts (Escape) without taking unwanted snaps.
#   - Automatically syncs to X11 clipboard and CopyQ history.
#   - Provides interactive Crop/View on notifications for dropdown captures.
# ══════════════════════════════════════════════════════════════════════════════

set -e

MODE="${1:-gui}"
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="$SAVE_DIR/screenshot_${TIMESTAMP}.png"

# Quick check if flameshot background daemon is responsive
ensure_flameshot_alive() {
    if pgrep -x flameshot >/dev/null 2>&1; then
        if ! timeout 0.5 flameshot --version >/dev/null 2>&1; then
            killall -9 flameshot 2>/dev/null || true
            sleep 0.1
        fi
    fi
}

# Copies to X11 clipboard and CopyQ clipboard manager
copy_to_clipboards() {
    local file="$1"
    xclip -selection clipboard -t image/png < "$file" 2>/dev/null || true
    if command -v copyq >/dev/null 2>&1; then
        copyq write image/png - < "$file" 2>/dev/null || true
    fi
}

# Handles post-capture clipboard and optional interactive crop/view
notify_and_handle() {
    local file="$1"
    local title="$2"
    local desc="$3"
    
    # Always copy to clipboard immediately
    copy_to_clipboards "$file"
    
    # Send interactive notification in background
    (
        ACTION=$(dunstify -a "screenshot" -u normal -t 6000 -i "$file" \
            -A "crop,✂️ Crop" -A "view,👁️ View" \
            "$title" "$desc" 2>/dev/null || true)
        
        if [ "$ACTION" = "crop" ]; then
            GEOM=$(slop -f "%wx%h+%x+%y" -b 2 -c 0.8,0.7,1,0.5 2>/dev/null || true)
            if [ -n "$GEOM" ]; then
                magick "$file" -crop "$GEOM" +repage "$file"
                copy_to_clipboards "$file"
                dunstify -a "screenshot" -u normal -t 3000 -i "$file" \
                    "✂️ Screenshot Cropped" "Saved to Screenshots & clipboard"
            fi
        elif [ "$ACTION" = "view" ]; then
            feh "$file" >/dev/null 2>&1 &
        fi
    ) &
}

case "$MODE" in
    gui)
        # Check if an X11 grab is active (e.g. dropdown menu, context menu, combobox)
        if command -v x11-grab-probe >/dev/null 2>&1 && ! x11-grab-probe; then
            # GRAB ACTIVE: An app currently owns the pointer/keyboard.
            # Running Flameshot GUI would block waiting for grab or force the menu to close.
            # Instead, take an instant root capture via maim to freeze the menu in place!
            if maim -u "$OUT_FILE" 2>/dev/null; then
                notify_and_handle "$OUT_FILE" "📸 Dropdown / Menu Captured" "Menu preserved intact! Click Crop to trim."
            fi
        else
            # GRAB FREE: Normal desktop capture via Flameshot GUI
            ensure_flameshot_alive
            set +e
            flameshot gui 2>/dev/null
            FS_EXIT=$?
            set -e
            
            # Exit code 2 means user pressed Escape to cancel — do not take fallback snap
            if [ "$FS_EXIT" -ne 0 ] && [ "$FS_EXIT" -ne 2 ]; then
                if maim -u "$OUT_FILE" 2>/dev/null; then
                    notify_and_handle "$OUT_FILE" "📸 Screenshot Captured" "Direct X11 capture saved to Screenshots & clipboard"
                fi
            fi
        fi
        ;;

    full)
        # Fast, zero-overhead fullscreen capture via maim
        if maim -u "$OUT_FILE" 2>/dev/null; then
            notify_and_handle "$OUT_FILE" "📸 Fullscreen Captured" "Saved to Screenshots & copied to clipboard"
        else
            flameshot full -p "$SAVE_DIR" -c 2>/dev/null || true
        fi
        ;;

    screen)
        # Screen / Monitor capture
        if maim -u "$OUT_FILE" 2>/dev/null; then
            notify_and_handle "$OUT_FILE" "📸 Screen Captured" "Saved to Screenshots & copied to clipboard"
        else
            flameshot screen -p "$SAVE_DIR" -c 2>/dev/null || true
        fi
        ;;

    delay)
        SECS="${2:-3}"
        for (( i=SECS; i>0; i-- )); do
            dunstify -a "screenshot" -u low -r 9999 -t 950 "📸 Screenshot in ${i}s..." "Open your menu or dropdown now!"
            sleep 1
        done
        # Instantly capture whatever is on screen without disturbing menus
        if maim -u "$OUT_FILE" 2>/dev/null; then
            notify_and_handle "$OUT_FILE" "📸 Timed Screenshot Captured" "Saved to Screenshots & copied to clipboard"
        fi
        ;;

    *)
        if maim -u "$OUT_FILE" 2>/dev/null; then
            notify_and_handle "$OUT_FILE" "📸 Screenshot Captured" "Saved to Screenshots & copied to clipboard"
        fi
        ;;
esac
