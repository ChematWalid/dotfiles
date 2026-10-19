#!/usr/bin/env bash
# ── switch-layout.sh ──────────────────────────────────────────────────────────
# Toggles keyboard layout between Belgian (AZERTY) and Arabic with Dunst OSD.

set -euo pipefail

current=$(setxkbmap -query 2>/dev/null | awk '/layout/ {split($2, layouts, ","); print layouts[1]}')

if [[ "$current" == "be" ]]; then
    setxkbmap -layout "ara,be" -option "grp:win_space_toggle"
    if [[ -d "${HOME}/.config/xkb" ]]; then
        setxkbmap -I"${HOME}/.config/xkb" -layout "ara,be" -option "grp:win_space_toggle" -print | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}" 2>/dev/null || true
    fi
    layout_name="Arabic (العربية)"
    flag="🇸🇦"
else
    setxkbmap -layout "be,ara" -option "grp:win_space_toggle"
    if [[ -d "${HOME}/.config/xkb" ]]; then
        setxkbmap -I"${HOME}/.config/xkb" -layout "be,ara" -option "grp:win_space_toggle" -print | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}" 2>/dev/null || true
    fi
    layout_name="Belgian (AZERTY)"
    flag="🇧🇪"
fi

# Ensure repeat rate (250ms delay, 50 repeats/sec) is preserved
xset r rate 250 50 2>/dev/null || true

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Keyboard" \
             -r 9993 \
             -u low \
             -i input-keyboard \
             "Keyboard Layout" \
             "${flag} ${layout_name}" \
             -t 1500 2>/dev/null || true
fi
