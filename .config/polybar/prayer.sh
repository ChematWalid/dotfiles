#!/usr/bin/env bash
set -euo pipefail

# Query Muslimtify's plain key/value output to avoid JSON cleanup and jq forks.
if ! HEADLESS_OUTPUT=$(muslimtify show --next --headless 2>/dev/null); then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

if [[ -z "$HEADLESS_OUTPUT" ]]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

prayer_raw=""
time_val=""
remaining=""
while IFS='=' read -r key value; do
    case "$key" in
        date) ;;
        remaining) remaining="$value" ;;
        *)
            prayer_raw="${key^}"
            time_val="$value"
            ;;
    esac
done <<< "$HEADLESS_OUTPUT"

if [[ -z "$prayer_raw" || -z "$time_val" ]]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

# Capitalize: first letter upper, rest unchanged (matches Python's str.capitalize())
prayer=${prayer_raw^}

# Format remaining time: "H:MM:SS" or "H:MM" → "Xh YYm" or "Ym"
IFS=':' read -r h m _s <<< "${remaining}:0"   # _s absorbs optional seconds field
h=${h:-0}; m=${m:-0}
if [ "$h" -gt 0 ]; then
    rem_str="${h}h $(printf '%02d' "$m")m"
else
    rem_str="${m}m"
fi

echo "%{F#94e2d5}🕌%{F-} ${prayer} ${time_val} %{F#6c7086}(${rem_str})%{F-}"
