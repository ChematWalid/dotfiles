#!/usr/bin/env bash
set -euo pipefail

# Fetch today's prayer times
JSON_ALL=$(muslimtify show --json 2>/dev/null)
JSON_NEXT=$(muslimtify show --next --json 2>/dev/null)

# Strip trailing commas before closing braces (muslimtify may emit invalid JSON)
CLEAN_ALL=$(echo "$JSON_ALL"   | sed 's/,\s*}/}/g')
CLEAN_NEXT=$(echo "$JSON_NEXT" | sed 's/,\s*}/}/g')

if [ -z "$JSON_ALL" ] || [ -z "$JSON_NEXT" ]; then
    notify-send -a "Muslimtify" "🕌 Prayer Times" "Could not fetch prayer times"
    exit 0
fi

# Parse individual prayer times
f_time=$(echo "$CLEAN_ALL" | jq -r '.prayers.fajr.time    // "--:--"')
d_time=$(echo "$CLEAN_ALL" | jq -r '.prayers.dhuhr.time   // "--:--"')
a_time=$(echo "$CLEAN_ALL" | jq -r '.prayers.asr.time     // "--:--"')
m_time=$(echo "$CLEAN_ALL" | jq -r '.prayers.maghrib.time // "--:--"')
i_time=$(echo "$CLEAN_ALL" | jq -r '.prayers.isha.time    // "--:--"')

# Parse next-prayer fields
next_raw=$(echo "$CLEAN_NEXT" | jq -r '.prayer   // ""')
next_r=$(echo   "$CLEAN_NEXT" | jq -r '.remaining // ""')

# Capitalize prayer name (matches Python's str.capitalize())
next_p=$(echo "$next_raw" | sed 's/./\u&/')

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
