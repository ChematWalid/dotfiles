#!/usr/bin/env bash
# ── toggle-polybar.sh ─────────────────────────────────────────────────────────
# Toggles Polybar visibility on demand (Alt + F).

set -euo pipefail

MAIN_PID=$(pgrep -f "polybar main" | head -1 || true)
TRAY_PID=$(pgrep -f "polybar tray" | head -1 || true)

if [[ -z "$MAIN_PID" ]]; then
    "${HOME}/.config/polybar/launch.sh" --show
elif xwininfo -name "polybar-main_DVI-I-1" 2>/dev/null | grep -q "IsViewable"; then
    # Main bar is currently visible -> HIDE EVERYTHING
    pkill -x "tray-autohide" 2>/dev/null || true
    [[ -n "$MAIN_PID" ]] && polybar-msg -p "$MAIN_PID" cmd hide >/dev/null 2>&1 || true
    [[ -n "$TRAY_PID" ]] && polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
else
    # Main bar is hidden -> SHOW main bar, keep tray hidden
    [[ -n "$MAIN_PID" ]] && polybar-msg -p "$MAIN_PID" cmd show >/dev/null 2>&1 || true
    [[ -n "$TRAY_PID" ]] && polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
fi
