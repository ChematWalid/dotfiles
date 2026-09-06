#!/usr/bin/env bash
# ── toggle-modules.sh ─────────────────────────────────────────────────────────
# Interactive Rofi module toggler for Polybar with automatic relaunch.

set -euo pipefail

readonly CONFIG="${HOME}/.config/polybar/config.ini"
readonly ALL_MODULES=("date" "prayer" "pulseaudio" "memory" "cpu" "temperature" "battery" "filesystem" "backlight" "wlan" "eth" "tray" "powermenu")

current_line=$(grep "^modules-right" "$CONFIG" || true)
current_modules="${current_line#*=}"

options=""
for mod in "${ALL_MODULES[@]}"; do
    if [[ " ${current_modules} " =~ " ${mod} " ]]; then
        options+="[x] ${mod}\n"
    else
        options+="[ ] ${mod}\n"
    fi
done

choice=$(
    printf "%b" "$options" | \
    rofi -dmenu -i \
         -p "󰒓  Toggle Module" \
         -theme "${HOME}/.config/rofi/config.rasi" \
         -theme-str 'window {width: 320px; height: 420px;} listview {lines: 12;}' 2>/dev/null || true
)

if [[ -n "$choice" ]]; then
    selected_mod="${choice//\[x\] /}"
    selected_mod="${selected_mod//\[ \] /}"
    selected_mod=$(echo "$selected_mod" | xargs)

    if [[ " ${current_modules} " =~ " ${selected_mod} " ]]; then
        new_modules=$(echo " ${current_modules} " | sed "s/ ${selected_mod} / /g" | xargs)
    else
        new_modules=""
        for mod in "${ALL_MODULES[@]}"; do
            if [[ " ${current_modules} " =~ " ${mod} " ]] || [[ "$mod" == "$selected_mod" ]]; then
                new_modules+="${mod} "
            fi
        done
        new_modules=$(echo "$new_modules" | xargs)
    fi

    sed -i.bak "s/^modules-right.*/modules-right = ${new_modules}/g" "$CONFIG"
    rm -f "${CONFIG}.bak"
    "${HOME}/.config/polybar/launch.sh"
fi
