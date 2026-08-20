#!/usr/bin/env python3
import subprocess
import sys
import os
import time
import threading

MAX_CHARS = 20         # Maximum visible characters in the rotating window
SCROLL_INTERVAL = 0.35 # Seconds per marquee step
SEPARATOR = "   •   "

lock = threading.Lock()
state = {
    "active_player": "",
    "status": "",
    "artist": "",
    "title": "",
    "full_text": "",
    "scroll_pos": 0,
}

def update_player_state():
    """Poll DBus for the latest active player and track information."""
    try:
        out = subprocess.check_output(
            ['playerctl', 'status', '-a', '-f', '{{playerName}}:::{{status}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        if not out:
            return None
            
        players = [line.split(':::') for line in out.splitlines() if ':::' in line]
        
        active_player, status = None, None
        for p, s in players:
            if s == "Playing":
                active_player, status = p, s
                break
        if not active_player:
            for p, s in players:
                if s == "Paused":
                    active_player, status = p, s
                    break
                    
        if not active_player or not status:
            return None
            
        artist = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{artist}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        title = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{title}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        full_text = f"{artist} - {title}" if artist and title else title or artist or "Media"
        
        return active_player, status, artist, title, full_text
    except Exception:
        return None

def dbus_listener():
    """Follow playerctl DBus events to immediately catch play/pause/skip."""
    global state
    while True:
        try:
            proc = subprocess.Popen(
                ['playerctl', 'metadata', '-a', '--format', '{{playerName}}:::{{status}}:::{{artist}}:::{{title}}', '--follow'],
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                universal_newlines=True,
                bufsize=1
            )
            for line in proc.stdout:
                line = line.strip()
                if not line:
                    continue
                res = update_player_state()
                with lock:
                    if res is None:
                        state["active_player"] = ""
                        state["status"] = ""
                        state["full_text"] = ""
                    else:
                        ap, st, ar, ti, ft = res
                        if ft != state["full_text"]:
                            state["scroll_pos"] = 0  # Reset marquee offset on new track
                        state["active_player"] = ap
                        state["status"] = st
                        state["artist"] = ar
                        state["title"] = ti
                        state["full_text"] = ft
            proc.wait()
        except Exception:
            pass
        time.sleep(0.5)

def get_marquee_slice(text, offset, width):
    """Return a rotating marquee slice of text with width characters."""
    if len(text) <= width:
        return text
    
    stream = text + SEPARATOR
    stream_len = len(stream)
    idx = offset % stream_len
    doubled = stream + stream
    return doubled[idx : idx + width]

def render(active_player, status, full_text, scroll_pos):
    if not active_player or not status or status == "Stopped" or not full_text:
        return ""
        
    play_icon = "%{F#a6e3a1}󰏥%{F-}" if status == "Playing" else "%{F#f9e2af}󰐌%{F-}"
    display_text = get_marquee_slice(full_text, scroll_pos, MAX_CHARS)
    
    prev = f"%{{F#89b4fa}}%{{A1:playerctl -p {active_player} previous 2>/dev/null:}}󰒮%{{A}}%{{F-}}"
    play = f"%{{A1:playerctl -p {active_player} play-pause 2>/dev/null:}}{play_icon}%{{A}}"
    next_btn = f"%{{F#89b4fa}}%{{A1:playerctl -p {active_player} next 2>/dev/null:}}󰒭%{{A}}%{{F-}}"
    note = "%{F#f5c2e7}󰎆%{F-}"
    
    return f"%{{T4}}{prev}  {play}  {next_btn}%{{T-}}   {note} %{{F#cdd6f4}}{display_text}%{{F-}}"

def main():
    # Initial state fetch
    res = update_player_state()
    if res:
        ap, st, ar, ti, ft = res
        state["active_player"] = ap
        state["status"] = st
        state["artist"] = ar
        state["title"] = ti
        state["full_text"] = ft

    # Start background event listener thread for zero-latency event updates
    t = threading.Thread(target=dbus_listener, daemon=True)
    t.start()

    last_rendered = None

    while True:
        with lock:
            ap = state["active_player"]
            st = state["status"]
            ft = state["full_text"]
            pos = state["scroll_pos"]

        rendered = render(ap, st, ft, pos)
        
        if rendered != last_rendered:
            print(rendered, flush=True)
            last_rendered = rendered

        # Advance scroll position while playing
        with lock:
            if state["status"] == "Playing" and len(state["full_text"]) > MAX_CHARS:
                state["scroll_pos"] += 1

        time.sleep(SCROLL_INTERVAL)

if __name__ == '__main__':
    main()
