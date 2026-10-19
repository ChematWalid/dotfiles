#!/usr/bin/env bash
# ── apply-input-settings.sh ───────────────────────────────────────────────────
# Applies low-latency keyboard repeat rate, dual layouts (BE/ARA), and raw 1:1 mouse input.

set -euo pipefail

apply_input() {
    local fallback_failed=false

    # 1. Keyboard Layouts. Hotplug and resume events can arrive in bursts;
    # preserve the user's currently selected layout when the configured map is
    # already active instead of recompiling it and resetting the group.
    local keyboard_state current_layout="" current_options="" key value
    keyboard_state=$(setxkbmap -query 2>/dev/null || true)
    while IFS=: read -r key value; do
        key=${key//[[:space:]]/}
        value=${value//[[:space:]]/}
        case "$key" in
            layout) current_layout=$value ;;
            options) current_options=$value ;;
        esac
    done <<< "$keyboard_state"

    if [[ "$current_layout" != "be,ara" || "$current_options" != "grp:win_space_toggle" ]]; then
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
    fi
    if [[ "$fallback_failed" == true ]]; then
        printf 'apply-input-settings: could not apply the Belgian/Arabic keyboard layout\n' >&2
    fi

    # Read the X server state once and avoid spawning three setters on every
    # input hotplug when repeat, blanking, and acceleration are already right.
    local xstate
    if xstate=$(LC_ALL=C xset q 2>/dev/null); then
        # 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec)
        if [[ ! "$xstate" =~ auto[[:space:]]repeat:[[:space:]]+on ]] ||
            [[ ! "$xstate" =~ auto[[:space:]]repeat[[:space:]]delay:[[:space:]]+250[[:space:]]+repeat[[:space:]]rate:[[:space:]]+50 ]]; then
            if ! xset r rate 250 50 2>/dev/null; then
                printf 'apply-input-settings: could not set keyboard repeat rate\n' >&2
            fi
        fi

        # 3. Disable Screen Blanking
        if [[ ! "$xstate" =~ prefer[[:space:]]blanking:[[:space:]]+no ]] ||
            [[ ! "$xstate" =~ timeout:[[:space:]]+0[[:space:]]+cycle: ]] ||
            [[ "$xstate" != *'DPMS is Disabled'* ]]; then
            if ! xset s off -dpms s noblank 2>/dev/null; then
                printf 'apply-input-settings: could not disable screen blanking\n' >&2
            fi
        fi

        # 4. Disable X11 core pointer acceleration
        if [[ ! "$xstate" =~ acceleration:[[:space:]]+0/1[[:space:]]+threshold:[[:space:]]+0 ]]; then
            if ! xset m 0 0 2>/dev/null; then
                printf 'apply-input-settings: could not disable pointer acceleration\n' >&2
            fi
        fi
    else
        # If state cannot be queried, retain the original best-effort behavior.
        xset r rate 250 50 2>/dev/null ||
            printf 'apply-input-settings: could not set keyboard repeat rate\n' >&2
        xset s off -dpms s noblank 2>/dev/null ||
            printf 'apply-input-settings: could not disable screen blanking\n' >&2
        xset m 0 0 2>/dev/null ||
            printf 'apply-input-settings: could not disable pointer acceleration\n' >&2
    fi

    # 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
    local devices id properties device_class="" device_line
    if ! devices=$(xinput list --short 2>/dev/null); then
        printf 'apply-input-settings: could not enumerate X11 input devices\n' >&2
        return
    fi
    local -a pointer_ids=()
    while IFS= read -r device_line; do
        case "$device_line" in
            *"Virtual core pointer"*) device_class=pointer ;;
            *"Virtual core keyboard"*) device_class=keyboard ;;
        esac
        if [[ "$device_class" == pointer \
            && "$device_line" != *"[master pointer"* \
            && "$device_line" =~ id=([0-9]+) ]]; then
            pointer_ids+=("${BASH_REMATCH[1]}")
        elif [[ "$device_line" == *"[floating slave"* \
            && "$device_line" =~ id=([0-9]+) ]]; then
            # Floating devices have no master-pointer section; query them too
            # and let the libinput-property check distinguish mice from keys.
            pointer_ids+=("${BASH_REMATCH[1]}")
        fi
    done <<< "$devices"

    for id in "${pointer_ids[@]}"; do
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
    done
}

apply_input
