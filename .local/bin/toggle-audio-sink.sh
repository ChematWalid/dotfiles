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
            -h string:x-dunst-stack-tag:audio-sink \
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

get_port_icon() {
    local name="${1,,}"
    if [[ "$name" == *headphone* || "$name" == *headset* ]]; then
        echo "audio-headphones"
    elif [[ "$name" == *speaker* || "$name" == *line* ]]; then
        echo "audio-speakers"
    else
        echo "audio-volume-high"
    fi
}

unmute_alsa_port() {
    local target="$1"
    local card="${2:-0}"
    # Unmute master hardware register
    amixer -c "$card" sset Master 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Master 100% unmute >/dev/null 2>&1 || true
    if [[ "$target" == *"headphone"* ]]; then
        amixer -c "$card" sset Headphone 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Headphone 100% unmute >/dev/null 2>&1 || true
    elif [[ "$target" == *"lineout"* || "$target" == *"speaker"* ]]; then
        amixer -c "$card" sset Front 100% unmute >/dev/null 2>&1 || amixer -c 0 sset Front 100% unmute >/dev/null 2>&1 || true
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
    sink_desc="$(pactl list sinks | awk -v s="$next_sink" '$1 == "Name:" && $2 == s {found=1} found && $1 == "Description:" {sub(/^Description: /, ""); print; exit}')"
    sink_desc="${sink_desc:-$next_sink}"

    icon="$(get_port_icon "$sink_desc")"

    # Unmute hardware DAC if the target sink is an ALSA card
    target_sink_info="$(pactl list sinks | awk -v s="$next_sink" '$1 == "Name:" && $2 == s {found=1; next} found && /^Sink #[0-9]+/ {exit} found {print}')"
    target_card="$(printf '%s\n' "$target_sink_info" | awk -F' = ' '/alsa\.(card|id) =/ {gsub(/[" ]/, "", $2); print $2; exit}')"
    target_port="$(printf '%s\n' "$target_sink_info" | awk -F': ' '/Active Port:/ {sub(/[ \t\r\n]+$/, "", $2); print $2; exit}')"
    unmute_alsa_port "$target_port" "${target_card:-0}"

    notify "Audio Output Changed" "$sink_desc" "$icon"
else
    # Single sink: toggle between active ports (e.g. Headphones vs Line Out / Speaker)
    sink_info="$(pactl list sinks | awk -v s="$default_sink" '
        $1 == "Name:" && $2 == s {found=1; next}
        found && /^Sink #[0-9]+/ {exit}
        found {print}
    ')"

    active_port="$(printf '%s\n' "$sink_info" | awk -F': ' '/Active Port:/ {sub(/[ \t\r\n]+$/, "", $2); print $2; exit}')"
    alsa_card="$(printf '%s\n' "$sink_info" | awk -F' = ' '/alsa\.(card|id) =/ {gsub(/[" ]/, "", $2); print $2; exit}')"
    alsa_card="${alsa_card:-0}"
    
    declare -A port_descs=()
    ports=()
    while IFS=$'\t' read -r p_id p_desc; do
        [[ -n "$p_id" ]] || continue
        ports+=("$p_id")
        port_descs["$p_id"]="${p_desc:-$p_id}"
    done < <(printf '%s\n' "$sink_info" | awk '
        /^[ \t]*Ports:[ \t]*$/ {in_ports=1; next}
        in_ports && /^[ \t]*(Active Port:|Formats:|[A-Z][a-zA-Z0-9 ]*:)/ {in_ports=0}
        in_ports && /^[ \t]+[^:]+:[ \t]*/ {
            if ($0 ~ /not available/ || $0 ~ /unavailable/ || $0 ~ /available:[ \t]*no/ || $0 ~ /availability:[ \t]*no/) next;
            match($0, /^[ \t]+([^:]+):[ \t]*(.*)$/, m);
            port = m[1];
            desc = m[2];
            sub(/[ \t]*\([^)]*\)[ \t]*$/, "", desc);
            print port "\t" (desc ? desc : port);
        }
    ')

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
        unmute_alsa_port "$next_port" "$alsa_card"

        port_name="${port_descs[$next_port]:-$next_port}"
        icon="$(get_port_icon "$port_name")"

        notify "Audio Output Changed" "$port_name" "$icon"
    elif [[ "${#ports[@]}" -eq 1 ]]; then
        if [[ -n "$active_port" && "$active_port" != "${ports[0]}" ]]; then
            next_port="${ports[0]}"
            pactl set-sink-port "$default_sink" "$next_port"
            unmute_alsa_port "$next_port" "$alsa_card"

            port_name="${port_descs[$next_port]:-$next_port}"
            icon="$(get_port_icon "$port_name")"

            notify "Audio Output Changed" "$port_name" "$icon"
        else
            notify "Audio Output" "Only one audio output available" "audio-volume-high"
        fi
    else
        notify "Audio Output" "No audio output available" "dialog-warning"
    fi
fi
