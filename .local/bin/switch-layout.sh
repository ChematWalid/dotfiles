#!/usr/bin/env bash
# ── switch-layout.sh ──────────────────────────────────────────────────────────
# Toggles keyboard layout between Belgian (AZERTY) and Arabic with Dunst OSD.

set -euo pipefail

report_error() {
    printf 'switch-layout: %s\n' "$1" >&2
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a "Keyboard" -r 9993 -u critical "Keyboard layout error" "$1" \
            -t 3000 2>/dev/null || true
    fi
}

readonly TOGGLE_BIN="${HOME}/.local/bin/xkb-group-toggle"

layout_name=""
flag=""

if [[ -x "$TOGGLE_BIN" ]]; then
    # Instantaneous XKB group lock toggle and Dunst notification in native C++
    # Preserves Latin keysym mapping in i3, repeat rate (250 50), and avoids process reloads
    if "$TOGGLE_BIN" toggle --notify >/dev/null 2>&1; then
        exit 0
    fi
fi

# Fallback path if native helper failed or is not installed
if [[ -z "$layout_name" ]]; then
    if ! keyboard_state=$(setxkbmap -query 2>/dev/null); then
        report_error 'could not read the current XKB layout'
        exit 1
    fi
    current=""
    while IFS= read -r line; do
        case "$line" in
            *layout:*)
                current=${line#*:}
                current=${current//[[:space:]]/}
                current=${current%%,*}
                break
                ;;
        esac
    done <<< "$keyboard_state"

    if [[ "$current" == "be" ]]; then
        layouts="ara,be"
        layout_name="Arabic (العربية)"
        flag="🇸🇦"
    else
        layouts="be,ara"
        layout_name="Belgian (AZERTY)"
        flag="🇧🇪"
    fi

    if setxkbmap -layout "$layouts" -option "" -option "grp:win_space_toggle" 2>/dev/null; then
        if [[ -d "${HOME}/.config/xkb" ]]; then
            setxkbmap -I"${HOME}/.config/xkb" -layout "$layouts" \
                -option "" -option "grp:win_space_toggle" -print 2>/dev/null \
                | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}" >/dev/null 2>&1 || true
        fi
    else
        report_error "could not apply the $layout_name layout"
        exit 1
    fi

    # Ensure repeat rate (250ms delay, 50 repeats/sec) is preserved after setxkbmap resets it
    if ! xset r rate 250 50 2>/dev/null; then
        report_error 'layout changed, but could not restore the keyboard repeat rate'
        exit 1
    fi
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Keyboard" \
             -r 9993 \
             -u low \
             -i input-keyboard \
             "Keyboard Layout" \
             "${flag} ${layout_name}" \
             -t 1500 2>/dev/null || true
fi

