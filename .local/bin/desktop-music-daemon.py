#!/usr/bin/env python3
import subprocess
import time
import threading
import os

OUTPUT_FILE = "/tmp/conky-music.txt"
lock = threading.Lock()
state = {"text": ""}

def get_track_info():
    try:
        out = subprocess.check_output(
            ['playerctl', 'status', '-a', '-f', '{{playerName}}:::{{status}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        if not out:
            try:
                mpc = subprocess.check_output(['mpc', 'current'], stderr=subprocess.DEVNULL).decode().strip()
                return f"󰐊 {mpc}" if mpc else ""
            except Exception:
                return ""
            
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
        if not active_player:
            return ""

        artist = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{artist}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()
        title = subprocess.check_output(
            ['playerctl', '-p', active_player, 'metadata', '--format', '{{title}}'],
            stderr=subprocess.DEVNULL
        ).decode().strip()

        if not title and not artist:
            return ""
            
        icon = "󰐊 " if status == "Playing" else "󰏤 "
        paused_tag = "" if status == "Playing" else "[Paused] "
        
        if artist and title:
            return f"{icon}{paused_tag}{artist} - {title}"
        return f"{icon}{paused_tag}{title or artist}"
    except Exception:
        return ""

def write_output(text):
    try:
        tmp = f"{OUTPUT_FILE}.tmp"
        with open(tmp, "w") as f:
            f.write(text.strip())
        os.replace(tmp, OUTPUT_FILE)
    except Exception:
        pass

def dbus_listener():
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
                info = get_track_info()
                with lock:
                    if info != state["text"]:
                        state["text"] = info
                        write_output(info)
            proc.wait()
        except Exception:
            pass
        time.sleep(0.5)

def main():
    initial = get_track_info()
    state["text"] = initial
    write_output(initial)

    t = threading.Thread(target=dbus_listener, daemon=True)
    t.start()

    while True:
        info = get_track_info()
        with lock:
            if info != state["text"]:
                state["text"] = info
                write_output(info)
        time.sleep(0.5)

if __name__ == '__main__':
    main()
