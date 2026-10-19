#!/usr/bin/env bash
# ── input-watch-daemon.sh ─────────────────────────────────────────────────────
# Listens for hardware input events (USB reconnect, hotplug, sleep/wake)
# and instantly re-applies input settings via apply-input-settings.sh.

set -euo pipefail

readonly APPLY_SCRIPT="${HOME}/.local/bin/apply-input-settings.sh"

# Apply initially
"$APPLY_SCRIPT"

# Stream udev input subsystem events
coproc UDEV_MONITOR {
    exec udevadm monitor --subsystem-match=input --udev 2>/dev/null
}
udev_pid=$UDEV_MONITOR_PID

while IFS= read -r -u "${UDEV_MONITOR[0]}" line; do
    if [[ "$line" =~ ^UDEV.*[[:space:]](add|bind|change)[[:space:]]/ ]]; then
        "$APPLY_SCRIPT"
    fi
done

# Preserve the old pipeline's failure behavior so systemd restarts a dead
# udev monitor instead of leaving an inactive watcher process behind.
wait "$udev_pid"
