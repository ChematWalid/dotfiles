#!/usr/bin/env bash
# ── toggle-tray.sh ────────────────────────────────────────────────────────────
# Toggle the Stalonetray grid and close it on the next outside click.
# Delegates to native compiled C++ tray-autohide for sub-millisecond execution.

set -euo pipefail

readonly BIN="${HOME}/.config/polybar/tray-autohide"
if [[ -x "$BIN" ]]; then
    exec "$BIN" --toggle
fi

exec tray-autohide --toggle
