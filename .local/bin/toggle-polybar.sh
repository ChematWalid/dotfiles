#!/usr/bin/env bash
# ── toggle-polybar.sh ─────────────────────────────────────────────────────────
# Toggles Polybar visibility on demand (Alt + F).

set -euo pipefail

source "${HOME}/.local/bin/scripts-common.sh"

STATE_DIR="$(get_dotfiles_runtime_dir)"
acquire_flock 9 "${STATE_DIR}/toggle-polybar.lock" || exit 0

MAIN_PID=$(pgrep -n -f "polybar main" || true)
VISIBILITY_STATE="${STATE_DIR}/polybar-main-visibility"
TRAY_STATE="${STATE_DIR}/polybar-tray-visibility"

if [[ -z "$MAIN_PID" ]]; then
    systemctl --user restart polybar.service
else
    if [[ -r "$VISIBILITY_STATE" && "$(< "$VISIBILITY_STATE")" == visible ]]; then
        MAIN_COMMAND=hide
        NEXT_STATE=hidden
    else
        MAIN_COMMAND=show
        NEXT_STATE=visible
    fi

    if ! timeout --signal=TERM --kill-after=1s 2s \
        polybar-msg -p "$MAIN_PID" cmd "$MAIN_COMMAND" >/dev/null 2>&1; then
        systemctl --user restart polybar.service
        exit 0
    fi

    printf '%s\n' "$NEXT_STATE" > "${VISIBILITY_STATE}.tmp.$$"
    mv -f "${VISIBILITY_STATE}.tmp.$$" "$VISIBILITY_STATE"

    # Keep the tray popup closed whenever the main bar is toggled.
    "${HOME}/.config/polybar/tray-autohide" --hide 2>/dev/null || true
fi
