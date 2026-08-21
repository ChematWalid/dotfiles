#!/usr/bin/env bash
# Toggle autotiling between automatic smart splitting and manual i3 splitting

if pgrep -x "autotiling" >/dev/null || pgrep -x "autotiling-rs" >/dev/null; then
    killall autotiling autotiling-rs 2>/dev/null || true
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling "🪟 Smart Autotiling" "Disabled (Manual i3 splitting)"
else
    autotiling -sr 1.0 2>/dev/null &
    dunstify -u normal -t 2000 -h string:x-dunst-stack-tag:tiling "🪟 Smart Autotiling" "Enabled (Automatic aspect-ratio splits)"
fi
