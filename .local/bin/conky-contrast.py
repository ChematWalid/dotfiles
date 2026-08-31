#!/usr/bin/env python3
import sys
import os
import subprocess
import colorsys
import math

COLORS_LUA = os.path.expanduser("~/.config/conky/colors.lua")

# Catppuccin palette entries (name -> (hex, R, G, B))
CATPPUCCIN_PALETTE = {
    # Light/Pastel accents (for dark & medium backgrounds)
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
    
    # Deep/Dark accents (for bright/light backgrounds)
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
    # Standard sRGB relative luminance formula
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
    
    # Inverted target color
    inv_r, inv_g, inv_b = 255 - r, 255 - g, 255 - b
    inv_h, inv_s, inv_v = colorsys.rgb_to_hsv(inv_r / 255.0, inv_g / 255.0, inv_b / 255.0)

    # Filter candidates by minimum contrast ratio (at least 3.0:1, ideally > 4.5:1)
    candidates = []
    for name, (hex_val, cr, cg, cb) in CATPPUCCIN_PALETTE.items():
        c_lum = rel_luminance(cr, cg, cb)
        c_ratio = contrast_ratio(bg_lum, c_lum)
        if c_ratio >= 2.5:
            # Score candidate based on contrast and hue similarity to inverted target
            c_h, c_s, c_v = colorsys.rgb_to_hsv(cr / 255.0, cg / 255.0, cb / 255.0)
            hue_diff = abs(c_h - inv_h)
            if hue_diff > 0.5:
                hue_diff = 1.0 - hue_diff
            score = (c_ratio * 2.0) - (hue_diff * 3.0)
            candidates.append((score, hex_val, name, c_ratio))

    candidates.sort(reverse=True, key=lambda x: x[0])

    if bg_lum < 0.35:
        # Dark wallpaper:
        # Time = warm Rosewater/Peach or Mauve, Date = Lavender/Sapphire, Music = Green/Teal
        time_color = '#f5e0dc'  # Rosewater
        date_color = '#b4befe'  # Lavender
        music_color = '#a6e3a1' # Green
        shade_color = '#11111b' # Deep dark shadow
    elif bg_lum > 0.60:
        # Very bright / light wallpaper (sky, white, daylight):
        # Time = Deep Mocha / Latte contrast, Date = Latte Blue, Music = Latte Green/Maroon
        time_color = '#11111b'  # Crust
        date_color = '#1e66f5'  # Latte Blue
        music_color = '#40a02b' # Latte Green
        shade_color = '#eff1f5' # Light shadow
    else:
        # Medium / In-between wallpaper: use the best scored inverted Catppuccin color
        best_hex = candidates[0][1] if candidates else '#f5e0dc'
        second_hex = candidates[1][1] if len(candidates) > 1 else '#b4befe'
        third_hex = candidates[2][1] if len(candidates) > 2 else '#a6e3a1'
        time_color = best_hex
        date_color = second_hex
        music_color = third_hex
        shade_color = '#11111b' if bg_lum < 0.5 else '#ffffff'

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
    
    # Reload conky to apply new colors
    subprocess.run(['killall -SIGUSR1 conky 2>/dev/null || true'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if __name__ == '__main__':
    main()
