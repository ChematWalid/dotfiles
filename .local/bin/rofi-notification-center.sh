#!/usr/bin/env python3
"""
Interactive Notification Center for Dunst & Rofi (Catppuccin Mocha themed)
Displays notification history in Rofi, allowing the user to view, restore,
focus applications, and clear history.
"""

import json
import subprocess
import sys
import os

def get_history():
    try:
        out = subprocess.check_output(["dunstctl", "history"], stderr=subprocess.DEVNULL)
        data = json.loads(out.decode("utf-8"))
        items = []
        raw_list = data.get("data", [[]])[0] if data.get("data") else []
        for entry in raw_list:
            item = {}
            for k, v in entry.items():
                item[k] = v.get("data")
            items.append(item)
        return items
    except Exception:
        return []

def main():
    history = get_history()
    
    if not history:
        subprocess.run([
            "rofi", "-e", "No notification history found.",
            "-theme", os.path.expanduser("~/.config/rofi/config.rasi")
        ])
        return

    menu_lines = []
    metadata = []

    menu_lines.append("󰎟  Redisplay Latest Notification")
    metadata.append({"action": "pop_latest"})

    menu_lines.append("󰎟  Clear All Notification History")
    metadata.append({"action": "clear_all"})

    for item in history:
        nid = item.get("id", 0)
        app = item.get("appname", "System")
        summary = item.get("summary", "")
        body = item.get("body", "").replace("\n", " ").strip()
        if len(body) > 60:
            body = body[:57] + "..."
        
        line = f"󰂚 [{app}] {summary}"
        if body and body != summary:
            line += f" — {body}"
        
        menu_lines.append(line)
        metadata.append({
            "action": "open",
            "id": nid,
            "appname": app,
            "summary": summary
        })

    rofi_input = "\n".join(menu_lines)

    rofi_proc = subprocess.Popen(
        [
            "rofi", "-dmenu", "-i",
            "-p", "󰂚 Notifications",
            "-format", "i",
            "-theme", os.path.expanduser("~/.config/rofi/config.rasi")
        ],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )

    stdout, _ = rofi_proc.communicate(input=rofi_input)
    selected_idx_str = stdout.strip()

    if not selected_idx_str or not selected_idx_str.isdigit():
        return

    idx = int(selected_idx_str)
    if idx < 0 or idx >= len(metadata):
        return

    choice = metadata[idx]
    action = choice.get("action")

    if action == "pop_latest":
        subprocess.run(["dunstctl", "history-pop"])
    elif action == "clear_all":
        subprocess.run(["dunstctl", "history-clear"])
    elif action == "open":
        nid = choice.get("id")
        app = choice.get("appname")
        if nid:
            subprocess.run(["dunstctl", "history-pop", str(nid)])
        if app:
            focus_script = os.path.expanduser("~/.config/dunst/focus-app.sh")
            if os.path.exists(focus_script):
                subprocess.run([focus_script, app])

if __name__ == "__main__":
    main()
