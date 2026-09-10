#!/usr/bin/env bash
# ── toggle-cava.sh ────────────────────────────────────────────────────────────
# Toggle a floating borderless Catppuccin Cava audio visualizer window.
# ─────────────────────────────────────────────────────────────────────────────
APP_CLASS="CavaPopup"

if pgrep -f "kitty --class ${APP_CLASS}" >/dev/null; then
    pkill -f "kitty --class ${APP_CLASS}"
else
    kitty --class "${APP_CLASS}" --title "Cava Audio Visualizer" \
        -o background_opacity=0.88 \
        -o window_padding_width=10 \
        -o confirm_os_window_close=0 \
        cava &
fi
