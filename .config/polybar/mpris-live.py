#!/usr/bin/env python3
import subprocess
import sys
import time

def get_mpris():
    try:
        out = subprocess.check_output(
            ['playerctl', 'status', '-a', '-f', '{{playerName}}:::{{status}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        if not out:
            return ""
            
        players = [line.split(':::') for line in out.splitlines() if ':::' in line]
        
        # Priority: Playing > Paused
        active_player = None
        status = None
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
            return ""
            
        artist = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{artist}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        title = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{title}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        
        play_icon = "%{F#a6e3a1}󰏥%{F-}" if status == "Playing" else "%{F#f9e2af}󰐌%{F-}"
        text = f"{artist} - {title}" if artist and title else title or "Media"
        
        if len(text) > 34:
            text = text[:32] + "…"
            
        prev = f"%{{F#89b4fa}}%{{A1:playerctl -p {active_player} previous 2>/dev/null:}}󰒮%{{A}}%{{F-}}"
        play = f"%{{A1:playerctl -p {active_player} play-pause 2>/dev/null:}}{play_icon}%{{A}}"
        next_btn = f"%{{F#89b4fa}}%{{A1:playerctl -p {active_player} next 2>/dev/null:}}󰒭%{{A}}%{{F-}}"
        note = "%{F#f5c2e7}󰎆%{F-}"
        
        return f"%{{T4}}{prev}  {play}  {next_btn}%{{T-}}   {note} %{{F#cdd6f4}}{text}%{{F-}}"
    except Exception:
        return ""

def main():
    last = None
    while True:
        curr = get_mpris()
        if curr != last:
            print(curr, flush=True)
            last = curr
        time.sleep(1)

if __name__ == '__main__':
    main()
