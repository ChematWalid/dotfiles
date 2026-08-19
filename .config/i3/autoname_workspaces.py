#!/usr/bin/env python3

import re
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
}

DEFAULT_ICON = ''

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
    tree = i3.get_tree()
    workspaces = tree.workspaces()
    
    for ws in workspaces:
        ws_num = get_workspace_number(ws.name)
        
        windows = ws.leaves()
        icons = []
        for w in windows:
            if w.window or w.name:
                icon = get_icon(w)
                if icon not in icons:
                    icons.append(icon)
        
        if icons:
            new_name = f"{ws_num}: {' '.join(icons)}"
        else:
            new_name = f"{ws_num}"
            
        if ws.name != new_name:
            i3.command(f'rename workspace "{ws.name}" to "{new_name}"')

def on_event(i3, event):
    update_workspaces(i3)

def main():
    i3 = i3ipc.Connection()
    update_workspaces(i3)

    # Listen to window and workspace events
    i3.on('window::new', on_event)
    i3.on('window::close', on_event)
    i3.on('window::move', on_event)
    i3.on('window::title', on_event)
    i3.on('workspace::focus', on_event)
    
    try:
        i3.main()
    except Exception:
        pass

if __name__ == '__main__':
    main()
