#!/usr/bin/env bash
# Toggle the Stalonetray grid and close it on the next outside click.
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
TRAY_STATE="${STATE_DIR}/polybar-tray-visibility"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"

# Consolidate dual root window tree sweeps into a single pass
{
    read -r TRAY_WINDOW || true
    read -r MAIN_WINDOW || true
} < <(xwininfo -root -tree 2>/dev/null | awk '
    $0 ~ /\("stalonetray" "stalonetray"\)/ && !tray { tray = $1 }
    $2 ~ /^"polybar-main_/ && !main { main = $1 }
    tray && main { exit }
    END { print tray; print main }
')

just_started=false
if [[ -z "$TRAY_WINDOW" ]] || ! pgrep -u "${UID:-$(id -u)}" -x stalonetray >/dev/null; then
    stalonetray_bin="$(command -v stalonetray || true)"
    if [[ -z "$stalonetray_bin" && -x "${HOME}/.local/bin/stalonetray" ]]; then
        stalonetray_bin="${HOME}/.local/bin/stalonetray"
    fi
    if [[ -n "$stalonetray_bin" && -f "${HOME}/.config/polybar/stalonetrayrc" ]]; then
        DISPLAY="${DISPLAY:-:0}" setsid "$stalonetray_bin" \
            -c "${HOME}/.config/polybar/stalonetrayrc" > /tmp/stalonetray.log 2>&1 &
        TRAY_WINDOW=$(timeout 3s xdotool search --sync --class --limit 1 '^stalonetray$' 2>/dev/null || true)
        just_started=true
    fi
fi

if [[ -z "$TRAY_WINDOW" ]]; then
    printf 'Stalonetray is not running and could not be started; check /tmp/stalonetray.log\n' >&2
    exit 1
fi

TRAY_INFO=$(xwininfo -id "$TRAY_WINDOW" 2>/dev/null || true)
if [[ -z "$TRAY_INFO" ]]; then
    printf 'Stalonetray window not accessible.\n' >&2
    exit 1
fi

pkill -x tray-autohide 2>/dev/null || true

if [[ "$just_started" == false && "$TRAY_INFO" == *"Map State: IsViewable"* ]]; then
    xdotool windowunmap "$TRAY_WINDOW"
    printf 'hidden\n' > "${TRAY_STATE}.tmp.$$"
    mv -f "${TRAY_STATE}.tmp.$$" "$TRAY_STATE"
else
    xdotool windowmap "$TRAY_WINDOW" windowraise "$TRAY_WINDOW"
    printf 'visible\n' > "${TRAY_STATE}.tmp.$$"
    mv -f "${TRAY_STATE}.tmp.$$" "$TRAY_STATE"
    setsid "${HOME}/.config/polybar/tray-autohide" stalonetray "$MAIN_WINDOW" \
        "$TRAY_STATE" "$TRAY_WINDOW" >/dev/null 2>&1 &
fi
