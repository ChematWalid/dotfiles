#!/usr/bin/env bash
# ── volume-osd.sh ─────────────────────────────────────────────────────────────
# High-performance volume control OSD with Dunst notification bar and rate limiting.

set -euo pipefail

readonly NOTIFICATION_ID=2593
readonly DEFAULT_STEP=1

action="${1:-}"
step="${2:-$DEFAULT_STEP}"
action_failed=false

if [[ ! "$step" =~ ^[0-9]+$ ]] || (( step < 1 )); then
    printf 'Usage: %s {up|down|mute|mic-mute} [step]\n' "${0##*/}" >&2
    printf 'Error: step must be a positive integer, got: %s\n' "$step" >&2
    exit 2
fi

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles"
[[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR"
LOCKFILE="${STATE_DIR}/volume-osd.lock"
LAST_NOTIFY_FILE="${STATE_DIR}/volume-osd-last-notify"
PENDING_NOTIFY_FILE="${STATE_DIR}/volume-osd-pending"
TRAILING_PID_FILE="${STATE_DIR}/volume-osd-trailing.pid"

# Serialize rapid key events to prevent race conditions while permitting fast bursting
exec 200>"$LOCKFILE"
flock -w 2 200 || exit 0

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

# Execute action and query the resulting state in a single pamixer call
case "$action" in
    up)
        if ! volume_state=$(pamixer --unmute --allow-boost --increase "$step" --get-volume-human 2>/dev/null); then
            action_failed=true
        fi
        ;;
    down)
        if ! volume_state=$(pamixer --unmute --allow-boost --decrease "$step" --get-volume-human 2>/dev/null); then
            action_failed=true
        fi
        ;;
    mute)
        if ! volume_state=$(pamixer -t --get-volume-human 2>/dev/null); then
            action_failed=true
        fi
        ;;
    mic-mute)
        if ! volume_state=$(pamixer --default-source -t --get-volume-human 2>/dev/null); then
            action_failed=true
        fi
        ;;
    '')
        if ! volume_state=$(pamixer --get-volume-human 2>/dev/null); then
            report_error 'Could not read output volume state.'
            exit 1
        fi
        ;;
    *)
        printf 'Usage: %s {up|down|mute|mic-mute} [step]\n' "${0##*/}" >&2
        exit 2
        ;;
esac

# Fallback in case the combined pamixer command failed
if [[ "$action_failed" == true ]] || [[ -z "${volume_state:-}" ]]; then
    if [[ "$action" == "mic-mute" ]]; then
        volume_state=$(pamixer --default-source --get-volume-human 2>/dev/null || echo "unknown")
    else
        volume_state=$(pamixer --get-volume-human 2>/dev/null || echo "unknown")
    fi
fi

# Release the lock immediately after audio hardware/daemon operations finish
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
    if [[ "$muted" == "true" ]]; then
        icon="audio-input-microphone-muted"
        text="Microphone: Muted"
    else
        icon="audio-input-microphone"
        text="Microphone: ${volume_state}"
    fi
elif [[ "$muted" == "true" ]] || [[ "$vol" -eq 0 ]]; then
    icon="audio-volume-muted"
    text="Muted"
    vol=0
else
    # Use audio-volume-high for >= 70% and overamplified (>100%) volume levels.
    # Note: audio-volume-overamplified does not exist in Papirus/Papirus-Dark
    # and causes Dunst to drop the sound icon completely.
    if [[ "$vol" -ge 70 ]]; then
        icon="audio-volume-high"
    elif [[ "$vol" -ge 30 ]]; then
        icon="audio-volume-medium"
    else
        icon="audio-volume-low"
    fi
    text="${vol}%"
fi

# Dispatch Dunst notification with sub-millisecond rate limiting (~60ms) and trailing async update
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
        trailing_running=false
        if [[ -f "$TRAILING_PID_FILE" ]]; then
            trailing_pid=$(< "$TRAILING_PID_FILE")
            if [[ "$trailing_pid" =~ ^[0-9]+$ ]] && kill -0 "$trailing_pid" 2>/dev/null; then
                trailing_running=true
            fi
        fi

        if [[ "$trailing_running" == false ]]; then
            (
                echo $$ > "$TRAILING_PID_FILE"
                trap 'rm -f "$TRAILING_PID_FILE"' EXIT
                sleep 0.08
                if [[ -f "$PENDING_NOTIFY_FILE" ]]; then
                    IFS=$'\t' read -r p_text p_vol p_icon < "$PENDING_NOTIFY_FILE" || true
                    rm -f "$PENDING_NOTIFY_FILE"
                    if [[ -n "${EPOCHREALTIME:-}" ]]; then
                        echo "$(( ${EPOCHREALTIME/[.]/} / 1000 ))" > "$LAST_NOTIFY_FILE"
                    else
                        date +%s%3N > "$LAST_NOTIFY_FILE"
                    fi
                    setsid dunstify -a "Volume" \
                             -r "$NOTIFICATION_ID" \
                             -u low \
                             -i "$p_icon" \
                             -h int:value:"$p_vol" \
                             -h "string:x-dunst-stack-tag:volume" \
                             "Volume: ${p_text}" \
                             -t 1200 >/dev/null 2>&1 &
                fi
            ) >/dev/null 2>&1 &
        fi
    fi
fi

if [[ "$action_failed" == true ]]; then
    report_error 'A pamixer command failed; showing the current device state.'
    exit 1
fi
