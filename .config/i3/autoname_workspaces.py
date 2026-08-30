#!/usr/bin/env python3

import re
import time
import i3ipc

WINDOW_ICONS = {
    # Terminals
    'kitty': '',
    'alacritty': '',
    'xterm': '',
    'urxvt': '',
    'gnome-terminal': '',
    'terminator': '',

    # Browsers
    'google-chrome': '󰊯',
    'chromium': '󰊯',
    'firefox': '󰈹',
    'librewolf': '󰈹',
    'zen-browser': '󰈹',
    'brave-browser': '󰊯',

    # Chat & Communication
    'telegramdesktop': '',
    'telegram-desktop': '',
    'telegram': '',
    'ayugram': '',
    '64gram': '',
    'discord': '󰙯',
    'webcord': '󰙯',
    'vesktop': '󰙯',
    'slack': '󰒱',

    # Code, Editors & IDEs
    'antigravity': '󰘦',
    'code': '󰨞',
    'vscodium': '󰨞',
    'code-oss': '󰨞',
    'cursor': '󰨞',
    'jetbrains-idea': '',
    'jetbrains-pycharm': '',
    'jetbrains-clion': '',
    'jetbrains-webstorm': '',
    'subl': '󰅪',
    'sublime_text': '󰅪',
    'emacs': '',
    'neovim': '',

    # Media & Entertainment
    'spotify': '',
    'vlc': '󰕼',
    'mpv': '󰕼',
    'gimp': '',
    'inkscape': '',
    'obs': '󰑋',
    'obs-studio': '󰑋',
    'steam': '󰓓',

    # Utilities & Files
    'thunar': '',
    'nautilus': '',
    'dolphin': '',
    'pcmanfm': '',
    'pavucontrol': '󰕾',
    'blueman-manager': '󰂯',
    'lxappearance': '󰔎',
    'postman': '󱂛',
    'dbeaver': '󰆼',
    'qbittorrent': '󰇚',

    # Mathematics & Science
    'kmplot': '',
    'kig': '',
    'labplot': '',
    'cantor': '',
    'geogebra': '',
    'maxima': '',
    'wxmaxima': '',
}

IGNORE_CLASSES = [
    'nm-applet',
    'blueman-applet',
    'conky',
    'polybar',
    'i3bar',
    'dunst',
    'notify-osd',
    'slop',
    'xsettingsd'
]

DEFAULT_ICON = ''

def is_ignored(window):
    cls = (window.window_class or '').lower()
    inst = (window.window_instance or '').lower()
    name = (window.name or '').lower()
    
    for ign in IGNORE_CLASSES:
        if ign in cls or ign in inst or ign in name:
            return True
    return False

def get_icon(window):
    if not window:
        return DEFAULT_ICON
    cls = (window.window_class or '').lower()
    inst = (window.window_instance or '').lower()
    name = (window.name or '').lower()
    
    for key, icon in WINDOW_ICONS.items():
        if key in cls or key in inst or key in name:
            return icon
    return DEFAULT_ICON

def get_workspace_number(name):
    match = re.match(r'^(\d+)', name)
    return match.group(1) if match else name

def update_workspaces(i3):
    try:
        tree = i3.get_tree()
        workspaces = tree.workspaces()
        
        for ws in workspaces:
            ws_num = get_workspace_number(ws.name)
            windows = ws.leaves()
            icons = []
            for w in windows:
                if (w.window or w.name) and not is_ignored(w):
                    icon = get_icon(w)
                    if icon not in icons:
                        icons.append(icon)
            
            if icons:
                new_name = f"{ws_num} {' '.join(icons)}"
            else:
                new_name = f"{ws_num}"
                
            if ws.name != new_name:
                i3.command(f'rename workspace "{ws.name}" to "{new_name}"')
    except Exception:
        pass

import threading

def on_event(i3, event):
    update_workspaces(i3)

def periodic_sync(i3):
    while True:
        try:
            update_workspaces(i3)
        except Exception:
            pass
        time.sleep(2)

def run():
    while True:
        try:
            i3 = i3ipc.Connection()
            update_workspaces(i3)
            
            # Start background periodic syncer
            t = threading.Thread(target=periodic_sync, args=(i3,), daemon=True)
            t.start()
            
            # Subscribe to all window, workspace, and mode events
            i3.on(i3ipc.Event.WINDOW, on_event)
            i3.on(i3ipc.Event.WORKSPACE, on_event)
            i3.on(i3ipc.Event.MODE, on_event)
            i3.main()
        except Exception:
            time.sleep(1)

if __name__ == '__main__':
    run()
