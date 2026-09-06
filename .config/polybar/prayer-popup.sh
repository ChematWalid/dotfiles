#!/usr/bin/env bash

# Fetch today's prayer times
JSON_ALL=$(muslimtify show --json 2>/dev/null)
JSON_NEXT=$(muslimtify show --next --json 2>/dev/null)

python3 -c '
import sys, json, re, subprocess

try:
    all_raw = sys.argv[1]
    next_raw = sys.argv[2]
    
    all_data = json.loads(re.sub(r",\s*}", "}", all_raw))
    prayers = all_data.get("prayers", {})
    
    next_data = json.loads(re.sub(r",\s*}", "}", next_raw))
    
    f_time = prayers.get("fajr", {}).get("time", "--:--")
    d_time = prayers.get("dhuhr", {}).get("time", "--:--")
    a_time = prayers.get("asr", {}).get("time", "--:--")
    m_time = prayers.get("maghrib", {}).get("time", "--:--")
    i_time = prayers.get("isha", {}).get("time", "--:--")
    
    next_p = next_data.get("prayer", "").capitalize()
    next_r = next_data.get("remaining", "")
    
    body = (
        f"🌅 Fajr:       {f_time}\n"
        f"☀️ Dhuhr:     {d_time}\n"
        f"🌤️ Asr:       {a_time}\n"
        f"🌇 Maghrib:   {m_time}\n"
        f"🌙 Isha:      {i_time}\n\n"
        f"⏳ Next: {next_p} in {next_r}"
    )
    
    subprocess.run([
        "notify-send",
        "-a", "Muslimtify",
        "-i", "muslimtify",
        "-u", "normal",
        "-t", "8000",
        "🕌 Today'\''s Prayer Times",
        body
    ])
except Exception as e:
    subprocess.run(["notify-send", "-a", "Muslimtify", "🕌 Prayer Times", "Could not fetch prayer times"])
' "$JSON_ALL" "$JSON_NEXT"
