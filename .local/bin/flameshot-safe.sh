#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  flameshot-safe.sh — Unstoppable Screenshot Launcher
#  Guarantees screenshot capture even if other software holds X11 grabs,
#  blocks the pointer, freezes, or attempts to stop/kill Flameshot.
# ══════════════════════════════════════════════════════════════════════════════

MODE="${1:-gui}"
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
OUT_FILE="$SAVE_DIR/screenshot_${TIMESTAMP}.png"

# 1. Release all active keyboard modifiers and pointer grabs in X11
xdotool keyup Super_L Super_R Alt_L Alt_R Control_L Control_R Shift_L Shift_R 2>/dev/null || true

# 2. Check if a stuck or zombie flameshot instance exists and clear it
if pgrep -x flameshot >/dev/null; then
    if ! timeout 0.6 flameshot --version >/dev/null 2>&1; then
        killall -9 flameshot 2>/dev/null || true
        sleep 0.1
    fi
fi

# 3. Attempt capture with automatic fallback
case "$MODE" in
    gui)
        # Attempt Flameshot GUI with a slight settling delay to clear transient app locks
        if ! timeout 120 flameshot gui --delay 150 2>/dev/null; then
            # If Flameshot GUI is blocked, killed, or denied by another window:
            sleep 0.1
            if maim -u "$OUT_FILE" 2>/dev/null; then
                xclip -selection clipboard -t image/png < "$OUT_FILE" 2>/dev/null || true
                dunstify -a "screenshot" -u normal -i "$OUT_FILE" "📸 Screenshot Captured" "Direct X11 capture saved to Screenshots & copied to clipboard"
            fi
        fi
        ;;
    full)
        if ! flameshot full -p "$SAVE_DIR" -c 2>/dev/null; then
            maim -u "$OUT_FILE" 2>/dev/null
            xclip -selection clipboard -t image/png < "$OUT_FILE" 2>/dev/null || true
            dunstify -a "screenshot" -u normal -i "$OUT_FILE" "📸 Fullscreen Captured" "Saved to Screenshots & copied to clipboard"
        fi
        ;;
    screen)
        if ! flameshot screen -p "$SAVE_DIR" -c 2>/dev/null; then
            maim -u "$OUT_FILE" 2>/dev/null
            xclip -selection clipboard -t image/png < "$OUT_FILE" 2>/dev/null || true
            dunstify -a "screenshot" -u normal -i "$OUT_FILE" "📸 Screen Captured" "Saved to Screenshots & copied to clipboard"
        fi
        ;;
    delay)
        SECS="${2:-3}"
        for (( i=SECS; i>0; i-- )); do
            dunstify -a "screenshot" -u low -r 9999 "📸 Screenshot in ${i}s..." "Open your menu or dropdown now!"
            sleep 1
        done
        flameshot gui --delay 100 2>/dev/null || maim -u "$OUT_FILE" 2>/dev/null
        ;;
    *)
        flameshot gui --delay 150 2>/dev/null || maim -u "$OUT_FILE" 2>/dev/null
        ;;
esac
