#!/usr/bin/env bash
# ── volume-osd.sh ─────────────────────────────────────────────────────────────
# High-performance volume control OSD with Dunst notification bar and rate limiting.

set -euo pipefail

readonly NOTIFICATION_ID=2593
readonly DEFAULT_STEP=1

action="${1:-}"
step="${2:-$DEFAULT_STEP}"
action_failed=false

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
LOCKFILE="${STATE_DIR}/volume-osd.lock"
LAST_NOTIFY_FILE="${STATE_DIR}/volume-osd-last-notify"
PENDING_NOTIFY_FILE="${STATE_DIR}/volume-osd-pending"

# Serialize rapid key events and prevent process fork congestion
exec 200>"$LOCKFILE"
flock -w 0.5 200 || exit 0

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
    if ! pamixer "$@" >/dev/null 2>&1; then
        action_failed=true
    fi
}

case "$action" in
    up)
        run_pamixer --unmute --allow-boost --increase "$step"
        ;;
    down)
        run_pamixer --unmute --allow-boost --decrease "$step"
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
        printf 'Usage: %s {up|down|mute|mic-mute} [step]\n' "${0##*/}" >&2
        exit 2
        ;;
esac

if [[ "$action" == "mic-mute" ]]; then
    if ! volume_state=$(pamixer --default-source --get-volume-human 2>/dev/null); then
        report_error 'Could not read microphone volume state.'
        exit 1
    fi
else
    if ! volume_state=$(pamixer --get-volume-human 2>/dev/null); then
        report_error 'Could not read output volume state.'
        exit 1
    fi
fi

# Release the lock immediately after pamixer finishes to prevent blocking subsequent
# events and prevent background processes (dunstify) from inheriting the lock fd.
flock -u 200 2>/dev/null || true
exec 200>&-

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

# Dispatch Dunst notification with rate limiting (~60ms) and asynchronous updates
if command -v dunstify >/dev/null 2>&1; then
    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        now_ms=$(( ${EPOCHREALTIME/[.]/} / 1000 ))
    else
        now_ms=$(date +%s%3N)
    fi
    last_notify=0
    [[ -f "$LAST_NOTIFY_FILE" ]] && last_notify=$(< "$LAST_NOTIFY_FILE")
    diff=$(( now_ms - last_notify ))

    if (( diff >= 60 || diff < 0 )); then
        printf '%s\n' "$now_ms" > "$LAST_NOTIFY_FILE"
        rm -f "$PENDING_NOTIFY_FILE"
        setsid dunstify -a "Volume" \
                 -r "$NOTIFICATION_ID" \
                 -u low \
                 -i "$icon" \
                 -h int:value:"$vol" \
                 -h "string:x-dunst-stack-tag:volume" \
                 "Volume: ${text}" \
                 -t 1200 >/dev/null 2>&1 &
    else
        # Save latest state for trailing update
        printf '%s\t%s\t%s\n' "$text" "$vol" "$icon" > "$PENDING_NOTIFY_FILE"
        if ! pgrep -f "volume-osd-trailing" >/dev/null 2>&1; then
            (
                exec -a "volume-osd-trailing" bash -c '
                    sleep 0.08
                    STATE_DIR="'"$STATE_DIR"'"
                    PENDING_FILE="'"$PENDING_NOTIFY_FILE"'"
                    LAST_FILE="'"$LAST_NOTIFY_FILE"'"
                    NOTIF_ID="'"$NOTIFICATION_ID"'"
                    if [[ -f "$PENDING_FILE" ]]; then
                        IFS=$'"'\t'"' read -r p_text p_vol p_icon < "$PENDING_FILE" || true
                        rm -f "$PENDING_FILE"
                        if [[ -n "${EPOCHREALTIME:-}" ]]; then
                            echo "$(( ${EPOCHREALTIME/[.]/} / 1000 ))" > "$LAST_FILE"
                        else
                            date +%s%3N > "$LAST_FILE"
                        fi
                        setsid dunstify -a "Volume" \
                                 -r "$NOTIF_ID" \
                                 -u low \
                                 -i "$p_icon" \
                                 -h int:value:"$p_vol" \
                                 -h "string:x-dunst-stack-tag:volume" \
                                 "Volume: ${p_text}" \
                                 -t 1200 >/dev/null 2>&1 &
                    fi
                '
            ) >/dev/null 2>&1 &
        fi
    fi
fi

if [[ "$action_failed" == true ]]; then
    report_error 'A pamixer command failed; showing the current device state.'
    exit 1
fi
