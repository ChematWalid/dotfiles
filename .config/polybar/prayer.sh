#!/usr/bin/env bash
set -euo pipefail

# Query Muslimtify for next prayer info
JSON_OUTPUT=$(muslimtify show --next --json 2>/dev/null)

if [ -z "$JSON_OUTPUT" ]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

# Strip trailing commas before closing braces (muslimtify may emit invalid JSON)
CLEAN_JSON=$(echo "$JSON_OUTPUT" | sed 's/,\s*}/}/g')

# Parse fields with jq
prayer_raw=$(echo "$CLEAN_JSON" | jq -r '.prayer // ""')
time_val=$(echo "$CLEAN_JSON"  | jq -r '.time // ""')
remaining=$(echo "$CLEAN_JSON" | jq -r '.remaining // ""')

# Capitalize: first letter upper, rest unchanged (matches Python's str.capitalize())
prayer=$(echo "$prayer_raw" | sed 's/./\u&/')

# Format remaining time: "H:MM:SS" or "H:MM" → "Xh YYm" or "Ym"
IFS=':' read -r h m _s <<< "${remaining}:0"   # _s absorbs optional seconds field
h=${h:-0}; m=${m:-0}
if [ "$h" -gt 0 ]; then
    rem_str="${h}h $(printf '%02d' "$m")m"
else
    rem_str="${m}m"
fi

if [ -z "$prayer_raw" ] && [ -z "$time_val" ]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

echo "%{F#94e2d5}🕌%{F-} ${prayer} ${time_val} %{F#6c7086}(${rem_str})%{F-}"
