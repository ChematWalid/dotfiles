#!/usr/bin/env bash
# ── toggle-autotiling.sh ──────────────────────────────────────────────────────
# Toggles between automatic aspect-ratio window tiling and manual i3 splitting.

set -euo pipefail

if pgrep -x "autotiling" >/dev/null 2>&1 || pgrep -x "autotiling-rs" >/dev/null 2>&1; then
    killall autotiling autotiling-rs 2>/dev/null || true
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling \
             "🪟 Smart Autotiling" "Disabled (Manual i3 splitting)" 2>/dev/null || true
else
    nohup autotiling -sr 1.0 >/dev/null 2>&1 &
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling \
             "🪟 Smart Autotiling" "Enabled (Automatic aspect-ratio splits)" 2>/dev/null || true
fi
