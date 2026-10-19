#!/usr/bin/env bash
# ── toggle-polybar.sh ─────────────────────────────────────────────────────────
# Toggles Polybar visibility on demand (Alt + F).

set -euo pipefail

# Repeated hotkey presses must not pile up IPC clients when Polybar is slow.
exec 9>"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/toggle-polybar.lock"
flock -n 9 || exit 0

MAIN_PID=$(pgrep -n -f "polybar main" || true)
TRAY_PID=$(pgrep -n -f "polybar tray" || true)
STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
VISIBILITY_STATE="${STATE_DIR}/polybar-main-visibility"
mkdir -p "$STATE_DIR"

if [[ -z "$MAIN_PID" ]]; then
    systemctl --user restart polybar.service
else
    if [[ "$(cat "$VISIBILITY_STATE" 2>/dev/null || true)" == visible ]]; then
        MAIN_COMMAND=hide
        NEXT_STATE=hidden
    else
        MAIN_COMMAND=show
        NEXT_STATE=visible
    fi

    pkill -x "tray-autohide" 2>/dev/null || true
    if ! timeout --signal=TERM --kill-after=1s 2s \
        polybar-msg -p "$MAIN_PID" cmd "$MAIN_COMMAND" >/dev/null 2>&1; then
        systemctl --user restart polybar.service
        exit 0
    fi

    printf '%s\n' "$NEXT_STATE" > "${VISIBILITY_STATE}.tmp.$$"
    mv -f "${VISIBILITY_STATE}.tmp.$$" "$VISIBILITY_STATE"

    # Keep the popup closed whenever the main bar is toggled.
    if [[ -n "$TRAY_PID" ]]; then
        timeout --signal=TERM --kill-after=1s 2s \
            polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1 || true
    fi
fi
