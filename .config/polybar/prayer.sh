#!/usr/bin/env bash
set -euo pipefail

# Query Muslimtify's plain key/value output to avoid JSON cleanup and jq forks.
if ! HEADLESS_OUTPUT=$(muslimtify show --next --headless 2>/dev/null) || [[ -z "$HEADLESS_OUTPUT" ]]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

prayer=""
time_val=""
remaining=""
while IFS='=' read -r key value; do
    case "$key" in
        date) ;;
        remaining) remaining="$value" ;;
        *)
            prayer="${key^}"
            time_val="$value"
            ;;
    esac
done <<< "$HEADLESS_OUTPUT"

if [[ -z "$prayer" || -z "$time_val" ]]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

# Format remaining time: "H:MM:SS" or "H:MM" → "Xh YYm" or "Ym"
IFS=':' read -r h m _s <<< "${remaining:-0}:0"   # _s absorbs optional seconds field
h=$(( 10#${h:-0} ))
m=$(( 10#${m:-0} ))
if [ "$h" -gt 0 ]; then
    printf -v rem_str '%dh %02dm' "$h" "$m"
else
    rem_str="${m}m"
fi

echo "%{F#94e2d5}🕌%{F-} ${prayer} ${time_val} %{F#6c7086}(${rem_str})%{F-}"
