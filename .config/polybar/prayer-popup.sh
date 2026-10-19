#!/usr/bin/env bash
set -euo pipefail

# Fetch today's and next prayer times in the CLI's key/value format.
if ! ALL_TIMES=$(muslimtify show --headless 2>/dev/null) \
    || ! NEXT_TIME=$(muslimtify show --next --headless 2>/dev/null) \
    || [[ -z "$ALL_TIMES" || -z "$NEXT_TIME" ]]; then
    notify-send -a "Muslimtify" "🕌 Prayer Times" "Could not fetch prayer times"
    exit 0
fi

declare -A prayer_times=()
while IFS='=' read -r key value; do
    prayer_times["$key"]="$value"
done <<< "$ALL_TIMES"

next_raw=""
next_r=""
while IFS='=' read -r key value; do
    case "$key" in
        date) ;;
        remaining) next_r="$value" ;;
        *) next_raw="$key" ;;
    esac
done <<< "$NEXT_TIME"

f_time=${prayer_times[fajr]:---:--}
d_time=${prayer_times[dhuhr]:---:--}
a_time=${prayer_times[asr]:---:--}
m_time=${prayer_times[maghrib]:---:--}
i_time=${prayer_times[isha]:---:--}
next_p=${next_raw^}

# Build notification body (same layout as the Python version)
body="🌅 Fajr:       ${f_time}
☀️ Dhuhr:     ${d_time}
🌤️ Asr:       ${a_time}
🌇 Maghrib:   ${m_time}
🌙 Isha:      ${i_time}

⏳ Next: ${next_p} in ${next_r}"

notify-send \
    -a "Muslimtify" \
    -i "muslimtify" \
    -u "normal" \
    -t "8000" \
    "🕌 Today's Prayer Times" \
    "$body"
