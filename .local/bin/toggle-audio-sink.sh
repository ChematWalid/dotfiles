#!/usr/bin/env bash
# ── toggle-audio-sink.sh ──────────────────────────────────────────────────────
# Fast, robust audio output toggler between sinks (or sink ports: headphones/speakers)
# with instant Dunst OSD feedback.

set -euo pipefail

NOTIFICATION_ID=2594

notify() {
    local title="$1"
    local desc="$2"
    local icon="$3"
    if command -v dunstify >/dev/null 2>&1; then
        dunstify -a "Audio" \
            -r "$NOTIFICATION_ID" \
            -u low \
            -i "$icon" \
            "$title" \
            "$desc" \
            -t 1500 2>/dev/null || true
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -a "Audio" \
            -h string:x-dunst-stack-tag:audio-sink \
            -u low \
            -i "$icon" \
            "$title" \
            "$desc" 2>/dev/null || true
    fi
}

if ! command -v pactl >/dev/null 2>&1; then
    notify "Audio Control" "pactl command not found" "dialog-error"
    exit 1
fi

default_sink="$(pactl get-default-sink 2>/dev/null || true)"
if [[ -z "$default_sink" ]]; then
    notify "Audio Control" "No default audio sink detected" "dialog-error"
    exit 1
fi

# Collect all available sinks
mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')
sink_count="${#sinks[@]}"

if [[ "$sink_count" -gt 1 ]]; then
    # Multiple sinks available: cycle to next sink
    next_sink=""
    for i in "${!sinks[@]}"; do
        if [[ "${sinks[$i]}" == "$default_sink" ]]; then
            next_index=$(( (i + 1) % sink_count ))
            next_sink="${sinks[$next_index]}"
            break
        fi
    done
    [[ -n "$next_sink" ]] || next_sink="${sinks[0]}"

    pactl set-default-sink "$next_sink"

    # Migrate any active audio streams to the newly selected sink
    while read -r stream_id _; do
        [[ -n "$stream_id" ]] || continue
        pactl move-sink-input "$stream_id" "$next_sink" 2>/dev/null || true
    done < <(pactl list short sink-inputs 2>/dev/null || true)

    # Determine description and icon
    sink_desc="$(pactl list sinks | awk -v s="$next_sink" '$0 ~ "Name: " s {found=1} found && $1 == "Description:" {sub(/^Description: /, ""); print; exit}')"
    sink_desc="${sink_desc:-$next_sink}"

    if [[ "$sink_desc" =~ (?i)headphone|headset ]]; then
        icon="audio-headphones"
    else
        icon="audio-speakers"
    fi

    notify "Audio Output Changed" "$sink_desc" "$icon"
else
    # Single sink: toggle between active ports (e.g. Headphones vs Line Out / Speaker)
    sink_info="$(pactl list sinks | awk -v s="$default_sink" '
        $0 ~ "Name: " s {found=1}
        found && /^Sink #[0-9]+/ && $0 !~ s {exit}
        found {print}
    ')"

    active_port="$(printf '%s\n' "$sink_info" | awk -F': ' '/Active Port:/ {print $2}')"
    mapfile -t ports < <(printf '%s\n' "$sink_info" | awk '/^[ \t]*analog-output-[a-zA-Z0-9_-]+:/ {gsub(/:/, "", $1); print $1}')

    if [[ "${#ports[@]}" -gt 1 ]]; then
        next_port=""
        for i in "${!ports[@]}"; do
            if [[ "${ports[$i]}" == "$active_port" ]]; then
                next_index=$(( (i + 1) % ${#ports[@]} ))
                next_port="${ports[$next_index]}"
                break
            fi
        done
        [[ -n "$next_port" ]] || next_port="${ports[0]}"

        pactl set-sink-port "$default_sink" "$next_port"

        if [[ "$next_port" =~ (?i)headphone ]]; then
            port_name="Headphones"
            icon="audio-headphones"
        elif [[ "$next_port" =~ (?i)speaker|lineout ]]; then
            port_name="Speakers (Line Out)"
            icon="audio-speakers"
        else
            port_name="${next_port#analog-output-}"
            icon="audio-volume-high"
        fi

        notify "Audio Output Changed" "$port_name" "$icon"
    else
        notify "Audio Output" "Only one audio output available" "audio-volume-high"
    fi
fi
