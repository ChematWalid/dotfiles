#!/usr/bin/env bash
# ── input-watch-daemon.sh ─────────────────────────────────────────────────────
# Listens for hardware input events (USB reconnect, hotplug, sleep/wake)
# and instantly re-applies input settings via apply-input-settings.sh.

set -euo pipefail

readonly APPLY_SCRIPT="${HOME}/.local/bin/apply-input-settings.sh"

# Apply initially
"$APPLY_SCRIPT" --no-spawn

# Stream udev input subsystem events
udevadm monitor --subsystem-match=input --udev 2>/dev/null | while read -r line; do
    if [[ "$line" =~ (add|bind|change) ]]; then
        sleep 0.2
        "$APPLY_SCRIPT" --no-spawn
    fi
done
