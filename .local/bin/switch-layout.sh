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

if ! keyboard_state=$(setxkbmap -query); then
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

if [[ -d "${HOME}/.config/xkb" ]]; then
    if ! setxkbmap -I"${HOME}/.config/xkb" -layout "$layouts" \
        -option "" -option "grp:win_space_toggle" -print \
        | xkbcomp -I"${HOME}/.config/xkb" - "${DISPLAY:-:0}"; then
        report_error "could not apply the $layout_name layout"
        exit 1
    fi
elif ! setxkbmap -layout "$layouts" -option "" -option "grp:win_space_toggle"; then
    report_error "could not apply the $layout_name layout"
    exit 1
fi

# Ensure repeat rate (250ms delay, 50 repeats/sec) is preserved
if ! xset r rate 250 50; then
    report_error 'layout changed, but could not restore the keyboard repeat rate'
    exit 1
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
