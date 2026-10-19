#!/usr/bin/env bash
# ── apply-input-settings.sh ───────────────────────────────────────────────────
# Applies low-latency keyboard repeat rate, dual layouts (BE/ARA), and raw 1:1 mouse input.

set -euo pipefail

apply_input() {
    # 1. Keyboard Layouts
    if [[ -d "${HOME}/.config/xkb" ]]; then
        if ! setxkbmap -I"${HOME}/.config/xkb" -layout "be,ara" \
            -option "" -option "grp:win_space_toggle" -print \
            | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}" 2>/dev/null; then
            setxkbmap -option "" 2>/dev/null || true
            setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null || true
        fi
    else
        setxkbmap -option "" 2>/dev/null || true
        setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null || true
    fi

    # 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec)
    xset r rate 250 50 2>/dev/null || true

    # 3. Disable Screen Blanking
    xset s off -dpms s noblank 2>/dev/null || true

    # 4. Disable X11 core pointer acceleration
    xset m 0 0 2>/dev/null || true

    # 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
    while IFS= read -r id; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        properties=$(xinput list-props "$id" 2>/dev/null) || continue
        [[ "$properties" == *"libinput Accel Profile Enabled"* ]] || continue

        local profile_matches=false speed_matches=false property value
        while IFS= read -r property; do
            case "$property" in
                *"libinput Accel Profile Enabled ("*"):"*)
                    value=${property#*:}
                    value=${value//[[:space:]]/}
                    [[ "$value" == "0,1,0" ]] && profile_matches=true
                    ;;
                *"libinput Accel Speed ("*"):"*)
                    value=${property#*:}
                    value=${value//[[:space:]]/}
                    [[ "$value" == "-0.250000" || "$value" == "-0.25" ]] && speed_matches=true
                    ;;
            esac
        done <<< "$properties"

        [[ "$profile_matches" == true ]] || \
            xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1, 0 2>/dev/null || true
        [[ "$speed_matches" == true ]] || \
            xinput set-prop "$id" "libinput Accel Speed" -0.25 2>/dev/null || true
    done < <(xinput list --id-only 2>/dev/null || true)
}

apply_input
