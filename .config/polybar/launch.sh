#!/usr/bin/env bash
# ── launch.sh ─────────────────────────────────────────────────────────────────
# Clean, reliable Polybar restart launcher with IPC initialization guard.

set -euo pipefail

# i3 can start Polybar before HOME has been imported into the session
# environment. Resolve it from passwd so Polybar's ${env:HOME} commands never
# collapse to paths such as /.config/polybar/mpris-live.sh.
if [[ -z "${HOME:-}" ]]; then
    HOME=$(getent passwd "$(id -u)" | cut -d: -f6)
fi
: "${HOME:?Could not determine home directory}"
export HOME

readonly STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
readonly VISIBILITY_STATE="${STATE_DIR}/polybar-main-visibility"
readonly TRAY_STATE="${STATE_DIR}/polybar-tray-visibility"
mkdir -p "$STATE_DIR"

# Read the actual X11 map state before killing the old bars. State files are a
# fallback for startup, when there is no existing window to inspect.
window_visibility() {
    local role window
    role="$1"
    window=$(xwininfo -root -tree 2>/dev/null \
        | awk -v prefix="\"polybar-${role}_" 'index($2, prefix) == 1 { print $1; exit }')
    [[ -n "$window" ]] || return 1

    if xwininfo -id "$window" 2>/dev/null | grep -q 'Map State: IsViewable'; then
        printf 'visible\n'
    else
        printf 'hidden\n'
    fi
}

MAIN_WAS_VISIBLE=$(window_visibility main || true)
TRAY_WAS_VISIBLE=$(window_visibility tray || true)
if [[ -z "$MAIN_WAS_VISIBLE" ]]; then
    MAIN_WAS_VISIBLE=$(cat "$VISIBILITY_STATE" 2>/dev/null || printf 'visible')
fi
if [[ -z "$TRAY_WAS_VISIBLE" ]]; then
    TRAY_WAS_VISIBLE=$(cat "$TRAY_STATE" 2>/dev/null || printf 'hidden')
fi

for module_script in mpris-live.sh datetime-tail.sh; do
    if [[ ! -x "${HOME}/.config/polybar/${module_script}" ]]; then
        printf 'Polybar module script is missing or not executable: %s\n' \
            "${HOME}/.config/polybar/${module_script}" >&2
        exit 1
    fi
done

if [[ ! -x "${HOME}/.config/polybar/network-eth-live" ]]; then
    printf 'Polybar network event helper is missing or not executable: %s\n' \
        "${HOME}/.config/polybar/network-eth-live" >&2
    exit 1
fi

if [[ ! -x "${HOME}/.local/bin/polybar-datetime" ]]; then
    printf 'Polybar datetime helper is missing or not executable: %s\n' \
        "${HOME}/.local/bin/polybar-datetime" >&2
    exit 1
fi

# Terminate existing Polybar and child module instances gracefully
killall polybar 2>/dev/null || true
pkill -x "mpris-live" 2>/dev/null || true

# Wait until all polybar processes have shut down (max 1s)
for _ in {1..10}; do
    if ! pgrep -u "${UID:-$(id -u)}" -x polybar >/dev/null; then
        break
    fi
    sleep 0.1
done

# Force kill any lingering processes if still alive
killall -9 polybar 2>/dev/null || true

# Launch main polybar
DISPLAY="${DISPLAY:-:0}" setsid polybar main -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar.log 2>&1 &

# Launch tray popup bar
DISPLAY="${DISPLAY:-:0}" setsid polybar tray -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar-tray.log 2>&1 &

# Wait for the main bar's IPC endpoint. systemd can then retry this launcher
# while the X display or its authorization cookie is still coming up.
MAIN_COMMAND=hide
case "${1:-}" in
    --show) MAIN_COMMAND=show ;;
    --hide) MAIN_COMMAND=hide ;;
    *)
        if [[ "$MAIN_WAS_VISIBLE" == hidden ]]; then
            MAIN_COMMAND=hide
        else
            MAIN_COMMAND=show
        fi
        ;;
esac
MAIN_READY=false
for _ in {1..20}; do
    MAIN_PID=$(pgrep -n -f "polybar main" || true)
    if [[ -n "$MAIN_PID" ]] && polybar-msg -p "$MAIN_PID" cmd "$MAIN_COMMAND" >/dev/null 2>&1; then
        MAIN_READY=true
        break
    fi
    sleep 0.05
done
if [[ "$MAIN_READY" != true ]]; then
    printf 'Polybar main did not initialize; see /tmp/polybar.log\n' >&2
    exit 1
fi

if [[ "$MAIN_COMMAND" == hide ]]; then
    printf 'hidden\n' > "${VISIBILITY_STATE}.tmp.$$"
else
    printf 'visible\n' > "${VISIBILITY_STATE}.tmp.$$"
fi
mv -f "${VISIBILITY_STATE}.tmp.$$" "$VISIBILITY_STATE"

# Restore the tray popup state and re-arm its outside-click watcher if it was
# open before the reload.
for _ in {1..20}; do
    TRAY_PID=$(pgrep -n -f "polybar tray" || true)
    if [[ -n "$TRAY_PID" ]] && polybar-msg -p "$TRAY_PID" cmd hide >/dev/null 2>&1; then
        if [[ "$TRAY_WAS_VISIBLE" == visible ]]; then
            MAIN_WINDOW=$(xwininfo -root -tree 2>/dev/null \
                | awk '$2 ~ /^"polybar-main_/ && !found { print $1; found = 1 }')
            setsid "${HOME}/.config/polybar/tray-autohide" "$TRAY_PID" "$MAIN_WINDOW" "$TRAY_STATE" >/dev/null 2>&1 &
            printf 'visible\n' > "${TRAY_STATE}.tmp.$$"
            polybar-msg -p "$TRAY_PID" cmd show >/dev/null 2>&1
        else
            printf 'hidden\n' > "${TRAY_STATE}.tmp.$$"
        fi
        mv -f "${TRAY_STATE}.tmp.$$" "$TRAY_STATE"
        break
    fi
    sleep 0.05
done
