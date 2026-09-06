#!/usr/bin/env bash
# ── toggle-tray.sh ────────────────────────────────────────────────────────────
# Toggles the Polybar system tray bar on and off.

set -euo pipefail

if pgrep -f "polybar.*tray" >/dev/null 2>&1; then
    pkill -f "polybar.*tray" 2>/dev/null || true
else
    nohup polybar tray > /tmp/polybar-tray.log 2>&1 &
fi
