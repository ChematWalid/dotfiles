#!/usr/bin/env bash
# ── toggle-tray.sh ────────────────────────────────────────────────────────────
# Toggles the Polybar system tray popup on and off with click-outside autohide.

set -euo pipefail

TRAY_PID=$(pgrep -o -f "polybar tray" || true)

if [[ -z "$TRAY_PID" ]]; then
    DISPLAY="${DISPLAY:-:0}" setsid polybar tray -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar-tray.log 2>&1 &
    TRAY_PID=$!

    # Wait for Polybar's IPC queue, then arm the watcher before showing the bar.
    for _ in {1..20}; do
        if polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1; then
            setsid "${HOME}/.config/polybar/tray-autohide" "$TRAY_PID" >/dev/null 2>&1 &
            polybar-msg -p "$TRAY_PID" cmd show >/dev/null
            exit 0
        fi
        if ! kill -0 "$TRAY_PID" 2>/dev/null; then
            break
        fi
        sleep 0.05
    done

    printf 'Could not initialize the Polybar tray popup; see /tmp/polybar-tray.log\n' >&2
    exit 1
fi

# Kill any running autohide watcher
pkill -x "tray-autohide" 2>/dev/null || true

TRAY_WINDOW=$(xwininfo -root -tree 2>/dev/null \
    | awk '$2 ~ /^"polybar-tray_/ { print $1; exit }')

if [[ -n "$TRAY_WINDOW" ]] \
    && xwininfo -id "$TRAY_WINDOW" 2>/dev/null | grep -q "Map State: IsViewable"; then
    # Tray is currently visible -> hide it
    polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
else
    # Tray is hidden -> arm click-outside handling before showing it.
    setsid "${HOME}/.config/polybar/tray-autohide" "$TRAY_PID" >/dev/null 2>&1 &
    polybar-msg -p "$TRAY_PID" cmd show >/dev/null
fi


