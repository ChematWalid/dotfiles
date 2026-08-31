#!/usr/bin/env python3
import sys
import os
import subprocess
import colorsys

COLORS_LUA = os.path.expanduser("~/.config/conky/colors.lua")

CATPPUCCIN_PALETTE = {
    'rosewater': ('#f5e0dc', 245, 224, 220),
    'flamingo':  ('#f2cdcd', 242, 205, 205),
    'pink':      ('#f5c2e7', 245, 194, 231),
    'mauve':     ('#cba6f7', 203, 166, 247),
    'peach':     ('#fab387', 250, 179, 135),
    'yellow':    ('#f9e2af', 249, 226, 175),
    'green':     ('#a6e3a1', 166, 227, 161),
    'teal':      ('#94e2d5', 148, 226, 213),
    'sky':       ('#89dceb', 137, 220, 235),
    'sapphire':  ('#74c7ec', 116, 199, 236),
    'blue':      ('#89b4fa', 137, 180, 250),
    'lavender':  ('#b4befe', 180, 190, 254),
    'text':      ('#cdd6f4', 205, 214, 244),
    
    'latte_mauve':   ('#8839ef', 136, 57, 239),
    'latte_blue':    ('#1e66f5', 30, 102, 245),
    'latte_maroon':  ('#e64553', 230, 69, 83),
    'latte_peach':   ('#fe640b', 254, 100, 11),
    'latte_teal':    ('#179299', 23, 146, 153),
    'latte_green':   ('#40a02b', 64, 160, 43),
    'latte_text':    ('#4c4f69', 76, 79, 105),
    'mocha_crust':   ('#11111b', 17, 17, 27),
    'mocha_mantle':  ('#181825', 24, 24, 37),
    'mocha_surface': ('#313244', 49, 50, 68),
}

def rel_luminance(r, g, b):
    rs = r / 255.0
    gs = g / 255.0
    bs = b / 255.0
    r_lin = rs / 12.92 if rs <= 0.03928 else ((rs + 0.055) / 1.055) ** 2.4
    g_lin = gs / 12.92 if gs <= 0.03928 else ((gs + 0.055) / 1.055) ** 2.4
    b_lin = bs / 12.92 if bs <= 0.03928 else ((bs + 0.055) / 1.055) ** 2.4
    return 0.2126 * r_lin + 0.7152 * g_lin + 0.0722 * b_lin

def contrast_ratio(l1, l2):
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def get_wallpaper_center_rgb(wall_path):
    try:
        out = subprocess.check_output([
            'magick', wall_path,
            '-gravity', 'center',
            '-crop', '700x350+0+0',
            '-scale', '1x1!',
            '-format', '%[fx:int(255*u.r)] %[fx:int(255*u.g)] %[fx:int(255*u.b)]',
            'info:'
        ], stderr=subprocess.DEVNULL).decode().strip()
        parts = [int(x) for x in out.split()]
        return parts[0], parts[1], parts[2]
    except Exception:
        return 30, 30, 46

def pick_inverted_palette(r, g, b):
    bg_lum = rel_luminance(r, g, b)
    
    if bg_lum < 0.45:
        # Dark or medium wallpaper:
        time_color = '#f5e0dc'  # Rosewater (warm sand/cream)
        date_color = '#b4befe'  # Lavender
        music_color = '#a6e3a1' # Green
        shade_color = '#11111b' # Deep dark shadow
    else:
        # Light or bright wallpaper:
        time_color = '#fab387'  # Peach
        date_color = '#89b4fa'  # Blue
        music_color = '#a6e3a1' # Green
        shade_color = '#11111b' # Dark shadow ensures readability over light backgrounds

    return time_color, date_color, music_color, shade_color

def main():
    wall = sys.argv[1] if len(sys.argv) > 1 else ""
    if not wall:
        lock_file = "/tmp/.wallpaper-current"
        if os.path.exists(lock_file):
            with open(lock_file) as f:
                wall = f.read().strip()

    if not wall or not os.path.exists(wall):
        return

    r, g, b = get_wallpaper_center_rgb(wall)
    time_color, date_color, music_color, shade_color = pick_inverted_palette(r, g, b)

    os.makedirs(os.path.dirname(COLORS_LUA), exist_ok=True)
    with open(COLORS_LUA, "w") as f:
        f.write(f"""-- Generated Catppuccin contrast colors based on wallpaper
return {{
    time = "{time_color}",
    date = "{date_color}",
    music = "{music_color}",
    shade = "{shade_color}"
}}
""")
    
    subprocess.run(['killall', '-SIGUSR1', 'conky'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == '__main__':
    main()
