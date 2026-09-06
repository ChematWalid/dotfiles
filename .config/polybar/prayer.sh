#!/usr/bin/env bash

# Query Muslimtify for next prayer info
JSON_OUTPUT=$(muslimtify show --next --json 2>/dev/null)

if [ -z "$JSON_OUTPUT" ]; then
    echo "%{F#6c7086}🕌 --:--%{F-}"
    exit 0
fi

python3 -c '
import sys, json, re

try:
    data = json.loads(re.sub(r",\s*}", "}", sys.argv[1]))
    prayer = data.get("prayer", "").capitalize()
    time = data.get("time", "")
    rem = data.get("remaining", "")
    
    parts = rem.split(":")
    h, m = int(parts[0]), int(parts[1])
    if h > 0:
        rem_str = f"{h}h {m:02d}m"
    else:
        rem_str = f"{m}m"
        
    print(f"%{{F#94e2d5}}🕌%{{F-}} {prayer} {time} %{{F#6c7086}}({rem_str})%{{F-}}")
except Exception:
    print("%{F#6c7086}🕌 --:--%{F-}")
' "$JSON_OUTPUT"
