#!/usr/bin/env python3
import subprocess
import time
import threading
import os

OUTPUT_FILE = "/tmp/conky-music.txt"
PID_FILE = "/tmp/.desktop-music-daemon.pid"

def ensure_single_instance():
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as pf:
                old_pid = int(pf.read().strip())
            if old_pid != os.getpid():
                os.kill(old_pid, 9)
        except Exception:
            pass
    try:
        with open(PID_FILE, 'w') as pf:
            pf.write(str(os.getpid()))
    except Exception:
        pass

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

        # 󰐊 = play triangle, 󰏤 = pause bars (NO [Paused] text)
        icon = "󰐊 " if status == "Playing" else "󰏤 "

        if artist and title:
            return f"{icon}{artist} - {title}"
        return f"{icon}{title or artist}"
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

def update_now():
    info = get_track_info()
    with lock:
        if info != state["text"]:
            state["text"] = info
            write_output(info)

def listen_command(cmd):
    while True:
        try:
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                universal_newlines=True,
                bufsize=1
            )
            for _ in proc.stdout:
                update_now()
            proc.wait()
        except Exception:
            pass
        time.sleep(0.3)

def main():
    ensure_single_instance()
    initial = get_track_info()
    state["text"] = initial
    write_output(initial)

    t1 = threading.Thread(
        target=listen_command,
        args=(['playerctl', 'metadata', '-a', '--format', '{{playerName}}:::{{status}}:::{{artist}}:::{{title}}', '--follow'],),
        daemon=True
    )
    t2 = threading.Thread(
        target=listen_command,
        args=(['playerctl', 'status', '-a', '--follow'],),
        daemon=True
    )
    t1.start()
    t2.start()

    while True:
        update_now()
        time.sleep(0.5)

if __name__ == '__main__':
    main()
