#!/usr/bin/env bash
# ── toggle-modules.sh ─────────────────────────────────────────────────────────
# Interactive Rofi module toggler for Polybar with automatic relaunch.

set -euo pipefail

readonly CONFIG="${HOME}/.config/polybar/config.ini"
readonly ALL_MODULES=("date" "prayer" "pulseaudio" "memory" "cpu" "temperature" "battery" "filesystem" "backlight" "wlan" "eth" "xkeyboard" "tray-toggle" "powermenu")

current_line=$(grep -m1 "^modules-right" "$CONFIG" || true)
current_modules="${current_line#*=}"
read -r -a current_module_list <<< "$current_modules"

contains_current_module() {
    local candidate
    for candidate in "${current_module_list[@]}"; do
        [[ "$candidate" == "$1" ]] && return 0
    done
    return 1
}

options=()
for mod in "${ALL_MODULES[@]}"; do
    if contains_current_module "$mod"; then
        options+=("[x] ${mod}")
    else
        options+=("[ ] ${mod}")
    fi
done

choice=$(
    printf '%s\n' "${options[@]}" | \
    rofi -dmenu -i \
         -p "󰒓  Toggle Module" \
         -theme "${HOME}/.config/rofi/config.rasi" \
         -theme-str 'window {width: 320px; height: 420px;} listview {lines: 12;}' 2>/dev/null || true
)

if [[ -n "$choice" ]]; then
    case "$choice" in
        "[x] "*|"[ ] "*) selected_mod="${choice:4}" ;;
        *) exit 0 ;;
    esac

    if contains_current_module "$selected_mod"; then
        new_modules=()
        for mod in "${current_module_list[@]}"; do
            [[ "$mod" == "$selected_mod" ]] || new_modules+=("$mod")
        done
    else
        new_modules=()
        for mod in "${ALL_MODULES[@]}"; do
            if contains_current_module "$mod" || [[ "$mod" == "$selected_mod" ]]; then
                new_modules+=("$mod")
            fi
        done
    fi

    new_modules_string="${new_modules[*]}"
    sed -i.bak "s/^modules-right.*/modules-right = ${new_modules_string}/g" "$CONFIG"
    rm -f "${CONFIG}.bak"
    "${HOME}/.config/polybar/launch.sh"
fi
