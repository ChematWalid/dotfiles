#!/usr/bin/env python3
"""
desktop-music-daemon.py — Real-time MPRIS music display daemon for desktop
Uses native DBus signals for sub-millisecond play/pause and track updates.
"""
import os
import sys
import subprocess
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

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

class MusicDaemon:
    def __init__(self):
        self.bus = dbus.SessionBus()
        self.current_text = ""
        self.players = {}  # name -> {'status': str, 'artist': str, 'title': str}

    def write_output(self, text):
        if text == self.current_text:
            return
        self.current_text = text
        try:
            tmp = f"{OUTPUT_FILE}.tmp"
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(text.strip())
            os.replace(tmp, OUTPUT_FILE)
        except Exception:
            pass

    def compute_display_text(self):
        active_player = None
        # Prefer currently playing player
        for name, data in self.players.items():
            if data.get('status') == 'Playing' and (data.get('title') or data.get('artist')):
                active_player = data
                break

        # Fallback to paused player
        if not active_player:
            for name, data in self.players.items():
                if data.get('status') == 'Paused' and (data.get('title') or data.get('artist')):
                    active_player = data
                    break

        if not active_player:
            # Fallback check for mpc if available
            try:
                mpc = subprocess.check_output(['mpc', 'current'], stderr=subprocess.DEVNULL).decode().strip()
                if mpc:
                    self.write_output(f"󰐊 {mpc}")
                    return
            except Exception:
                pass
            self.write_output("")
            return

        status = active_player.get('status', 'Stopped')
        artist = active_player.get('artist', '')
        title = active_player.get('title', '')

        if not title and not artist:
            self.write_output("")
            return

        icon = "󰐊 " if status == "Playing" else "󰏤 "
        if artist and title:
            text = f"{icon}{artist} - {title}"
        else:
            text = f"{icon}{title or artist}"

        self.write_output(text)

    def read_player_props(self, bus_name):
        try:
            player_obj = self.bus.get_object(bus_name, '/org/mpris/MediaPlayer2')
            props_iface = dbus.Interface(player_obj, 'org.freedesktop.DBus.Properties')
            props = props_iface.GetAll('org.mpris.MediaPlayer2.Player')
            
            status = str(props.get('PlaybackStatus', 'Stopped'))
            meta = props.get('Metadata', {})
            
            artist = ""
            if 'xesam:artist' in meta:
                raw_artist = meta['xesam:artist']
                if isinstance(raw_artist, (list, dbus.Array)) and len(raw_artist) > 0:
                    artist = str(raw_artist[0])
                else:
                    artist = str(raw_artist)
            
            title = str(meta.get('xesam:title', ''))
            
            self.players[bus_name] = {
                'status': status,
                'artist': artist,
                'title': title
            }
        except Exception:
            self.players.pop(bus_name, None)

    def scan_all_players(self):
        try:
            for name in self.bus.list_names():
                if name.startswith('org.mpris.MediaPlayer2.'):
                    self.read_player_props(name)
        except Exception:
            pass
        self.compute_display_text()

    def on_properties_changed(self, interface_name, changed_properties, invalidated_properties, path=None, sender=None):
        if interface_name != 'org.mpris.MediaPlayer2.Player':
            return
        
        # Identify or refresh sender player
        if sender:
            # Look up owner or update existing entry
            if sender not in self.players:
                self.players[sender] = {'status': 'Stopped', 'artist': '', 'title': ''}
            
            if 'PlaybackStatus' in changed_properties:
                self.players[sender]['status'] = str(changed_properties['PlaybackStatus'])
                
            if 'Metadata' in changed_properties:
                meta = changed_properties['Metadata']
                artist = ""
                if 'xesam:artist' in meta:
                    raw_artist = meta['xesam:artist']
                    if isinstance(raw_artist, (list, dbus.Array)) and len(raw_artist) > 0:
                        artist = str(raw_artist[0])
                    else:
                        artist = str(raw_artist)
                title = str(meta.get('xesam:title', ''))
                self.players[sender]['artist'] = artist
                self.players[sender]['title'] = title
            
            self.compute_display_text()
        else:
            self.scan_all_players()

    def on_name_owner_changed(self, name, old_owner, new_owner):
        if name.startswith('org.mpris.MediaPlayer2.'):
            if not new_owner:
                self.players.pop(name, None)
                self.players.pop(old_owner, None)
                self.compute_display_text()
            else:
                self.read_player_props(name)
                self.compute_display_text()

def main():
    ensure_single_instance()
    DBusGMainLoop(set_as_default=True)
    
    daemon = MusicDaemon()
    daemon.scan_all_players()

    # Listen to real-time property changes (play/pause/metadata) on MPRIS interface
    daemon.bus.add_signal_receiver(
        daemon.on_properties_changed,
        signal_name='PropertiesChanged',
        dbus_interface='org.freedesktop.DBus.Properties',
        path='/org/mpris/MediaPlayer2',
        sender_keyword='sender'
    )

    # Listen to players opening/closing
    daemon.bus.add_signal_receiver(
        daemon.on_name_owner_changed,
        signal_name='NameOwnerChanged',
        dbus_interface='org.freedesktop.DBus'
    )

    # Periodic scan every 2s as a fallback
    GLib.timeout_add_seconds(2, lambda: (daemon.scan_all_players(), True)[1])

    loop = GLib.MainLoop()
    try:
        loop.run()
    except KeyboardInterrupt:
        pass

if __name__ == '__main__':
    main()
