#!/usr/bin/env bash
# ── toggle-tray.sh ────────────────────────────────────────────────────────────
# Toggles the Polybar system tray popup on and off with click-outside autohide.

set -euo pipefail

TRAY_PID=$(pgrep -f "polybar tray" | head -1 || true)

if [[ -z "$TRAY_PID" ]]; then
    DISPLAY="${DISPLAY:-:0}" setsid polybar tray -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar-tray.log 2>&1 &
    exit 0
fi

# Kill any running autohide watcher
pkill -x "tray-autohide" 2>/dev/null || true

if xwininfo -name "polybar-tray_DVI-I-1" 2>/dev/null | grep -q "IsViewable"; then
    # Tray is currently visible -> hide it
    polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
else
    # Tray is hidden -> show it and launch click-outside watcher (native C binary)
    polybar-msg -p "$TRAY_PID" cmd show >/dev/null 2>&1 || true
    setsid "${HOME}/.config/polybar/tray-autohide" "$TRAY_PID" >/dev/null 2>&1 &
fi


