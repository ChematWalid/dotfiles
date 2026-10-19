#!/usr/bin/env bash
# ── volume-osd.sh ─────────────────────────────────────────────────────────────
# Volume control OSD with Dunst notification bar and synchronous audio feedback.

set -euo pipefail

readonly STEP=1
readonly NOTIFICATION_ID=2593

action="${1:-}"
action_failed=false

report_error() {
    printf '%s\n' "$1" >&2
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a "Volume" -u critical -r "$NOTIFICATION_ID" "$1" \
            -t 3000 2>/dev/null || true
    fi
}

if ! command -v pamixer >/dev/null 2>&1; then
    report_error 'Volume control requires pamixer, but it is not installed.'
    exit 1
fi

run_pamixer() {
    if ! pamixer "$@" >/dev/null; then
        action_failed=true
    fi
}

case "$action" in
    up)
        run_pamixer -u
        run_pamixer --allow-boost -i "$STEP"
        ;;
    down)
        run_pamixer -u
        run_pamixer -d "$STEP"
        ;;
    mute)
        run_pamixer -t
        ;;
    mic-mute)
        run_pamixer --default-source -t
        ;;
    '')
        ;;
    *)
        printf 'Usage: %s {up|down|mute|mic-mute}\n' "${0##*/}" >&2
        exit 2
        ;;
esac

if [[ "$action" == "mic-mute" ]]; then
    if ! volume_state=$(pamixer --default-source --get-volume-human); then
        report_error 'Could not read microphone volume state.'
        exit 1
    fi
else
    if ! volume_state=$(pamixer --get-volume-human); then
        report_error 'Could not read output volume state.'
        exit 1
    fi
fi

if [[ "$volume_state" == "muted" ]]; then
    muted=true
    vol=0
else
    muted=false
    vol="${volume_state%%%}"
    if [[ ! "$vol" =~ ^[0-9]+$ ]]; then
        report_error "Unexpected volume value from pamixer: $volume_state"
        exit 1
    fi
fi

if [[ "$action" == "mic-mute" ]]; then
    icon="audio-input-microphone"
    text="Microphone: ${volume_state}"
elif [[ "$muted" == "true" ]] || [[ "$vol" -eq 0 ]]; then
    icon="audio-volume-muted"
    text="Muted"
    vol=0
else
    if [[ "$vol" -ge 70 ]]; then
        icon="audio-volume-high"
    elif [[ "$vol" -ge 30 ]]; then
        icon="audio-volume-medium"
    else
        icon="audio-volume-low"
    fi
    text="${vol}%"
fi

if command -v dunstify >/dev/null 2>&1; then
    dunstify -a "Volume" \
             -r "$NOTIFICATION_ID" \
             -u low \
             -i "$icon" \
             -h int:value:"$vol" \
             "Volume: ${text}" \
             -t 1200 2>/dev/null || true
fi

if [[ "$action_failed" == true ]]; then
    report_error 'A pamixer command failed; showing the current device state.'
    exit 1
fi
