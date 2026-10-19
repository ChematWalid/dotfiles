#!/usr/bin/env bash
# ── toggle-autotiling.sh ──────────────────────────────────────────────────────
# Toggles between automatic aspect-ratio window tiling and manual i3 splitting.

set -euo pipefail

if systemctl --user is-active --quiet autotiling.service; then
    systemctl --user stop autotiling.service
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling \
             "🪟 Smart Autotiling" "Disabled (Manual i3 splitting)" 2>/dev/null || true
else
    systemctl --user start autotiling.service
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling \
             "🪟 Smart Autotiling" "Enabled (Automatic aspect-ratio splits)" 2>/dev/null || true
fi
