#!/usr/bin/env bash
# ── apply-input-settings.sh ───────────────────────────────────────────────────
# Applies low-latency keyboard repeat rate, dual layouts (BE/ARA), and raw 1:1 mouse input.

set -euo pipefail

apply_input() {
    local fallback_failed=false

    # 1. Keyboard Layouts
    if [[ -d "${HOME}/.config/xkb" ]]; then
        if ! setxkbmap -I"${HOME}/.config/xkb" -layout "be,ara" \
            -option "" -option "grp:win_space_toggle" -print \
            | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}" 2>/dev/null; then
            setxkbmap -option "" 2>/dev/null || fallback_failed=true
            setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null \
                || fallback_failed=true
        fi
    else
        setxkbmap -option "" 2>/dev/null || true
        setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null \
            || fallback_failed=true
    fi
    if [[ "$fallback_failed" == true ]]; then
        printf 'apply-input-settings: could not apply the Belgian/Arabic keyboard layout\n' >&2
    fi

    # 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec)
    if ! xset r rate 250 50 2>/dev/null; then
        printf 'apply-input-settings: could not set keyboard repeat rate\n' >&2
    fi

    # 3. Disable Screen Blanking
    if ! xset s off -dpms s noblank 2>/dev/null; then
        printf 'apply-input-settings: could not disable screen blanking\n' >&2
    fi

    # 4. Disable X11 core pointer acceleration
    if ! xset m 0 0 2>/dev/null; then
        printf 'apply-input-settings: could not disable pointer acceleration\n' >&2
    fi

    # 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
    local input_ids id properties
    if ! input_ids=$(xinput list --id-only 2>/dev/null); then
        printf 'apply-input-settings: could not enumerate X11 input devices\n' >&2
        return
    fi
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
            xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1, 0 2>/dev/null \
                || printf 'apply-input-settings: could not set acceleration profile for device %s\n' "$id" >&2
        [[ "$speed_matches" == true ]] || \
            xinput set-prop "$id" "libinput Accel Speed" -0.25 2>/dev/null \
                || printf 'apply-input-settings: could not set acceleration speed for device %s\n' "$id" >&2
    done <<< "$input_ids"
}

apply_input
