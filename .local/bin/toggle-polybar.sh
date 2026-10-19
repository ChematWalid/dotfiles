#!/usr/bin/env bash
# ── toggle-polybar.sh ─────────────────────────────────────────────────────────
# Toggles Polybar visibility on demand (Alt + F).

set -euo pipefail

MAIN_PID=$(pgrep -o -f "polybar main" || true)
TRAY_PID=$(pgrep -o -f "polybar tray" || true)

if [[ -z "$MAIN_PID" ]]; then
    systemctl --user restart polybar.service
else
    pkill -x "tray-autohide" 2>/dev/null || true
    if ! polybar-msg -p "$MAIN_PID" cmd toggle >/dev/null 2>&1; then
        systemctl --user restart polybar.service
        exit 0
    fi

    # Keep the popup closed whenever the main bar is toggled.
    if [[ -n "$TRAY_PID" ]]; then
        polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
    fi
fi
