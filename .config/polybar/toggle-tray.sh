#!/usr/bin/env bash
# Toggle the Stalonetray grid and close it on the next outside click.
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
TRAY_STATE="${STATE_DIR}/polybar-tray-visibility"
mkdir -p "$STATE_DIR"

find_window() {
    xwininfo -root -tree 2>/dev/null \
        | awk 'tolower($0) ~ /stalonetray/ && !found { window = $1; found = 1 } END { if (found) print window }'
}

TRAY_WINDOW=$(find_window)
if [[ -z "$TRAY_WINDOW" ]] || ! xwininfo -id "$TRAY_WINDOW" >/dev/null 2>&1; then
    printf 'Stalonetray is not running; restart the Polybar user service first.\n' >&2
    exit 1
fi

MAIN_WINDOW=$(xwininfo -root -tree 2>/dev/null \
    | awk '$2 ~ /^"polybar-main_/ && !found { window = $1; found = 1 } END { if (found) print window }')

TRAY_INFO=$(xwininfo -id "$TRAY_WINDOW" 2>/dev/null || true)
if [[ "$TRAY_INFO" == *"Map State: IsViewable"* ]]; then
    pkill -x tray-autohide 2>/dev/null || true
    xdotool windowunmap "$TRAY_WINDOW"
    printf 'hidden\n' > "${TRAY_STATE}.tmp.$$"
    mv -f "${TRAY_STATE}.tmp.$$" "$TRAY_STATE"
else
    pkill -x tray-autohide 2>/dev/null || true
    setsid "${HOME}/.config/polybar/tray-autohide" stalonetray "$MAIN_WINDOW" \
        "$TRAY_STATE" "$TRAY_WINDOW" >/dev/null 2>&1 &
    printf 'visible\n' > "${TRAY_STATE}.tmp.$$"
    mv -f "${TRAY_STATE}.tmp.$$" "$TRAY_STATE"
    xdotool windowmap "$TRAY_WINDOW"
    xdotool windowraise "$TRAY_WINDOW"
fi
