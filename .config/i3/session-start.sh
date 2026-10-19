#!/usr/bin/env bash
set -euo pipefail

# The user manager and D-Bus can outlive i3 and retain stale X11 credentials.
# Refresh systemd's display credentials and D-Bus's display/Qt environment
# before starting graphical services or allowing GUI services to auto-activate.
systemctl --user import-environment DISPLAY XAUTHORITY I3SOCK
LC_ALL=en_US.UTF-8 QT_QPA_PLATFORMTHEME=qt6ct \
    dbus-update-activation-environment DISPLAY XAUTHORITY LC_ALL QT_QPA_PLATFORMTHEME
systemctl --user start i3-session.target

# Make the display compositor and tray host available before tray clients.
systemctl --user start picom.service || true
systemctl --user restart polybar.service || true

start_copyq_when_display_ready() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local lock_file="${runtime_dir}/copyq-start.lock"
    local auth_path="${XAUTHORITY:-}"
    local auth_dir auth_name event event_fd watch_pid

    exec {copyq_lock_fd}>"$lock_file"
    flock -n "$copyq_lock_fd" || return 0

    if xset q >/dev/null 2>&1; then
        systemctl --user start copyq.service || true
        return 0
    fi

    if [[ -z "$auth_path" ]]; then
        printf 'session-start: X11 is not ready and XAUTHORITY is unset; delaying CopyQ until i3 reload\n' >&2
        return 0
    fi

    auth_dir="${auth_path%/*}"
    auth_name="${auth_path##*/}"
    [[ "$auth_dir" == "$auth_path" ]] && auth_dir=.
    if [[ ! -d "$auth_dir" ]] || ! command -v inotifywait >/dev/null 2>&1; then
        printf 'session-start: cannot watch XAUTHORITY directory; delaying CopyQ until i3 reload\n' >&2
        return 0
    fi

    # Wait on the Xauthority file's filesystem event instead of retrying a GUI
    # process against a stale cookie. The second xset check closes the race
    # between the initial check and inotify subscription setup.
    coproc XAUTH_WATCH {
        exec env LC_ALL=C timeout 90s inotifywait --monitor \
            --event close_write,attrib,create,moved_to \
            --format '%f' "$auth_dir" 2>&1
    }
    event_fd=${XAUTH_WATCH[0]}
    watch_pid=$XAUTH_WATCH_PID

    while IFS= read -r -u "$event_fd" event; do
        [[ "$event" == 'Watches established.' ]] && break
    done

    if xset q >/dev/null 2>&1; then
        kill "$watch_pid" 2>/dev/null || true
        wait "$watch_pid" 2>/dev/null || true
        systemctl --user start copyq.service || true
        return 0
    fi

    while IFS= read -r -u "$event_fd" event; do
        if [[ "$event" == "$auth_name" ]] && xset q >/dev/null 2>&1; then
            systemctl --user start copyq.service || true
            break
        fi
    done

    kill "$watch_pid" 2>/dev/null || true
    wait "$watch_pid" 2>/dev/null || true
}

# Start the rest after the X11 display and Polybar tray are initialized.
systemctl --user start \
    conky.service \
    wallpaper-rotate.service \
    autotiling.service \
    input-watch.service \
    i3-autoname.service || true

# CopyQ aborts on an invalid Xauthority cookie. Start it immediately when X11
# is ready, or after the authority file changes and a connection succeeds.
start_copyq_when_display_ready
