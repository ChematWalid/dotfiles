#!/usr/bin/env bash
# ── input-watch-daemon.sh ─────────────────────────────────────────────────────
# Listens for hardware input events (USB reconnect, hotplug, sleep/wake)
# and instantly re-applies input settings via apply-input-settings.sh.

set -euo pipefail

readonly APPLY_SCRIPT="${HOME}/.local/bin/apply-input-settings.sh"

# Stream udev input subsystem events
coproc UDEV_MONITOR {
    exec env LC_ALL=C udevadm monitor --subsystem-match=input --udev 2>/dev/null
}
udev_pid=$UDEV_MONITOR_PID
udev_fd=${UDEV_MONITOR[0]}

# udevadm prints this after opening its monitor socket. Waiting for that
# handshake closes the startup gap where a newly attached device could be
# missed before the first settings pass.
monitor_ready=false
while IFS= read -r -u "$udev_fd" line; do
    if [[ "$line" == 'UDEV - the event which udev sends out after rule processing' ]]; then
        monitor_ready=true
        break
    fi
done

if [[ "$monitor_ready" != true ]]; then
    wait "$udev_pid"
    exit 1
fi

# Apply initially after the event subscription is active.
"$APPLY_SCRIPT"

while IFS= read -r -u "$udev_fd" line; do
    if [[ "$line" =~ ^UDEV.*[[:space:]](add|bind|change)[[:space:]]/ ]]; then
        "$APPLY_SCRIPT"
    fi
done

# Preserve the old pipeline's failure behavior so systemd restarts a dead
# udev monitor instead of leaving an inactive watcher process behind.
wait "$udev_pid"
