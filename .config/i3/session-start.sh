#!/usr/bin/env bash
set -euo pipefail

# The user manager and D-Bus can outlive i3 and retain stale X11 credentials.
# Refresh systemd's display credentials and D-Bus's display/Qt environment
# before starting graphical services or allowing GUI services to auto-activate.
systemctl --user import-environment DISPLAY XAUTHORITY I3SOCK DBUS_SESSION_BUS_ADDRESS
LC_ALL=en_US.UTF-8 QT_QPA_PLATFORMTHEME=qt6ct \
    dbus-update-activation-environment --systemd DISPLAY XAUTHORITY I3SOCK DBUS_SESSION_BUS_ADDRESS LC_ALL QT_QPA_PLATFORMTHEME

wait_for_x11_ready() {
    local auth_path="${XAUTHORITY:-}"
    local auth_dir auth_name event event_fd watch_pid

    if xset q >/dev/null 2>&1; then
        return 0
    fi
    if [[ -z "$auth_path" ]]; then
        printf 'session-start: X11 is not ready and XAUTHORITY is unset; graphical services were not started\n' >&2
        return 1
    fi

    auth_dir="${auth_path%/*}"
    auth_name="${auth_path##*/}"
    [[ "$auth_dir" == "$auth_path" ]] && auth_dir=.
    if [[ ! -d "$auth_dir" ]] || ! command -v inotifywait >/dev/null 2>&1; then
        printf 'session-start: cannot watch XAUTHORITY for X11 readiness; graphical services were not started\n' >&2
        return 1
    fi

    # Wait for the display manager to finish writing its X11 cookie. Starting
    # graphical units before this event makes feh, picom, and Polybar fail and
    # can exhaust their systemd restart limits during login.
    coproc XAUTH_WATCH {
        exec env LC_ALL=C timeout 120s inotifywait --monitor \
            --event close_write,attrib,create,moved_to \
            --format '%f' "$auth_dir" 2>&1
    }
    event_fd=${XAUTH_WATCH[0]}
    watch_pid=$XAUTH_WATCH_PID

    while IFS= read -r -u "$event_fd" event; do
        [[ "$event" == 'Watches established.' ]] && break
    done

    # Close the race between the initial xset check and watcher registration.
    if xset q >/dev/null 2>&1; then
        kill "$watch_pid" 2>/dev/null || true
        wait "$watch_pid" 2>/dev/null || true
        return 0
    fi

    while IFS= read -r -u "$event_fd" event; do
        if [[ "$event" == "$auth_name" ]] && xset q >/dev/null 2>&1; then
            kill "$watch_pid" 2>/dev/null || true
            wait "$watch_pid" 2>/dev/null || true
            return 0
        fi
    done

    kill "$watch_pid" 2>/dev/null || true
    wait "$watch_pid" 2>/dev/null || true
    printf 'session-start: X11 did not become ready within 120 seconds; graphical services were not started\n' >&2
    return 1
}

if ! wait_for_x11_ready; then
    exit 1
fi

systemctl --user start i3-session.target

# Make the display compositor and tray host available before tray clients.
systemctl --user start picom.service || true
systemctl --user restart polybar.service || true
systemctl --user start dunst.service || true

start_copyq_once() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local lock_file="${runtime_dir}/copyq-start.lock"

    exec {copyq_lock_fd}>"$lock_file"
    flock -n "$copyq_lock_fd" || return 0
    systemctl --user start copyq.service || true
}

# Start the rest after the X11 display and Polybar tray are initialized.
systemctl --user start \
    conky.service \
    wallpaper-rotate.service \
    autotiling.service \
    input-watch.service \
    i3-autoname.service || true

# Ensure ALSA hardware DACs are unmuted (resilience against soft-mixer bypass)
amixer -c PCH sset Master 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Master 100% unmute >/dev/null 2>&1 || true
amixer -c PCH sset Headphone 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Headphone 100% unmute >/dev/null 2>&1 || true
amixer -c PCH sset Front 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Front 100% unmute >/dev/null 2>&1 || true

# The shared X11 readiness gate above also makes this safe for CopyQ. Keep the
# lock so parallel i3 config reloads cannot issue duplicate starts.
start_copyq_once
