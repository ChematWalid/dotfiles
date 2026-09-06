#!/usr/bin/env bash
# ── toggle-polybar.sh ─────────────────────────────────────────────────────────
# Toggles Polybar visibility on demand (Alt + F).

set -euo pipefail

if pgrep -u "$UID" -x polybar >/dev/null 2>&1; then
    polybar-msg cmd toggle >/dev/null 2>&1 || true
else
    "${HOME}/.config/polybar/launch.sh"
    sleep 0.2
    polybar-msg cmd show >/dev/null 2>&1 || true
fi
