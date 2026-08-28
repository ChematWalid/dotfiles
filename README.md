<div align="center">

# 🌸 walid's dotfiles

**Catppuccin Mocha · i3wm · Polybar · Arch Linux**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![i3wm](https://img.shields.io/badge/i3wm-4C566A?style=flat-square&logo=i3&logoColor=white)](https://i3wm.org)
[![Catppuccin](https://img.shields.io/badge/Catppuccin-Mocha-CBA6F7?style=flat-square)](https://catppuccin.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

</div>

---

## 📸 Overview

A fully themed **Catppuccin Mocha** desktop on Arch Linux, built around **i3wm** as the window manager. Every component — from the compositor to the clipboard manager — is configured and version-controlled here.

### Stack

| Category | Tool |
|---|---|
| WM | i3wm + autotiling |
| Bar | Polybar (custom scripts: MPRIS live, keyboard layout, xkeyboard) |
| Compositor | Picom (xrender, tuned for NVIDIA GT 610) |
| Terminal | Kitty · Alacritty |
| Shell | Zsh + Oh-My-Zsh + fzf-tab + atuin |
| Editor | Neovim (ThePrimeagen config, lazy.nvim, auto-save) |
| Launcher | Rofi (apps, windows, calculator, websearch, powermenu) |
| Notifications | Dunst (Catppuccin, click-to-focus, OSD bypass for volume/brightness) |
| Prompt | Starship |
| File manager | lf · Yazi · Thunar |
| Clipboard | CopyQ + Greenclip |
| Music | MPD + Ncmpcpp + CAVA visualizer |
| Password manager | Bitwarden CLI + rbw + rofi-rbw |
| GTK theme | catppuccin-gtk-theme-mocha |
| Icons | Papirus-Dark + papirus-folders-catppuccin |
| Cursor | Bibata-Modern-Classic |
| Font | JetBrainsMono Nerd Font |
| Lock screen | i3lock-color (Catppuccin blur) |
| Display manager | SDDM + catppuccin-mocha-mauve theme |

---

## ⚡ One-shot install (fresh Arch)

> Assumes a base Arch Linux install with network access and `git` available.

```bash
git clone https://github.com/ACEECA1/dotfiles ~/dotfiles
cd ~/dotfiles && bash install.sh
```

### What `install.sh` does

1. **`pacman -Syu`** — system update
2. **296 pacman packages** — full desktop stack from `pkglist-pacman-names.txt`
3. **yay** — AUR helper (built from source if not present)
4. **36 AUR packages** — themes, tools, and apps from `pkglist-aur-names.txt`
5. **Oh-My-Zsh** + 5 custom plugins (fzf-tab, autosuggestions, completions, fast-syntax-highlighting, catppuccin theme)
6. **Symlinks** all dotfiles into `~/.config`, `~/.local/bin`, `~/.local/share`
7. **Fonts** — Iosevka, Fantasque Sans Mono, Feather, Material Icons, Terminus
8. **Wallpaper** → `~/Pictures/catppuccin-wall-dark.jpg`
9. **/etc configs** — SDDM theme, sysctl performance tweaks, logind no-sleep
10. **Systemd user services** — copyq, i3-autoname, mpd, syncthing, wireplumber
11. **Default shell** → zsh

---

## 🔧 After install (manual steps)

```bash
sudo reboot                            # apply everything cleanly

gh auth login                          # GitHub CLI
rbw login                              # Bitwarden / Vaultwarden
ssh-keygen -t ed25519 -C "you@mail"   # SSH key (or restore from backup)

hdd-route all                          # symlink Steam/VSCode/Docker/JetBrains to HDD
mise install                           # restore node/python/go/java runtimes
rclone config                          # re-add cloud remotes
# open localhost:8384 for Syncthing pairing
```

> **fstab warning:** `install.sh` shows a diff and asks before touching `/etc/fstab`.
> UUIDs are hardware-specific — verify with `blkid` before applying.

---

## 🗂 Repo structure

```
dotfiles/
├── .config/           # All XDG config dirs (i3, polybar, nvim, kitty, rofi…)
├── .local/
│   ├── bin/           # Custom scripts (lock.sh, switch-layout.sh, hdd-route…)
│   └── share/         # Desktop entries, navi cheatsheets, tealdeer pages, fonts
├── etc/               # System configs (fstab, sddm, sysctl, logind)
├── install.sh         # 🚀 One-shot bootstrap script
├── pkglist-pacman.txt # pacman explicit packages (with versions)
├── pkglist-aur.txt    # AUR packages (with versions)
├── wallpaper.jpg      # Catppuccin Mocha 1920×1080 wallpaper
├── TOOLS_GUIDE.md     # Full keybinding & tool reference manual
└── README.md          # This file
```

---

## ⌨️ Key bindings (i3)

> `Mod` = **Alt**, `Win` = **Super/Windows key**

| Shortcut | Action |
|---|---|
| `Mod + Return` | Open Kitty terminal |
| `Win + Return` | Open Alacritty terminal |
| `Mod + D` | Rofi app launcher |
| `Mod + Space` | Rofi app launcher |
| `Win + Space` | Toggle keyboard layout (BE ↔ AR) |
| `Win + L` | Lock screen (Catppuccin blur) |
| `Win + P` | Rofi password auto-typer (rbw) |
| `Mod + V` / `Win + V` | CopyQ clipboard history |
| `Mod + U` / `Win + U` | Dropdown scratchpad terminal |
| `Mod + =` / `Win + C` | Rofi calculator |
| `Mod + Shift + W` | Google websearch via Rofi |
| `Print` / `Mod + Shift + S` | Flameshot GUI screenshot |
| `Shift + Print` | Flameshot fullscreen screenshot |
| `Mod + Shift + T` | Toggle autotiling |
| `Win + Shift + T` | Toggle autotiling |
| `Mod + Q` | Kill focused window |
| `Mod + F` | Fullscreen toggle |
| `Mod + Shift + Space` | Toggle floating |
| `Mod + 1–10` | Switch workspace |
| `Mod + Shift + 1–10` | Move container to workspace |

Full reference → [`TOOLS_GUIDE.md`](TOOLS_GUIDE.md)

---

## 🔑 Custom scripts (`~/.local/bin`)

| Script | Purpose |
|---|---|
| `lock.sh` | Catppuccin blur i3lock-color lockscreen |
| `switch-layout.sh` | Toggle BE/Arabic keyboard with Dunst OSD |
| `input-watch-daemon.sh` | udev watcher — re-applies keyboard rate + mouse raw input on hotplug/wake |
| `apply-input-settings.sh` | Set keyboard rate (250/50), flat mouse profile, xset no-DPMS |
| `volume-osd.sh` | Volume up/down/mute with Dunst OSD notification |
| `brightness-osd.sh` | Brightness control with Dunst OSD |
| `hdd-route` | Symlink Steam/VSCode/Docker/JetBrains/Brave cache to HDD |
| `rofi-websearch.sh` | Google search from Rofi prompt |
| `bw` / `bw-local` | Bitwarden CLI wrappers (local Vaultwarden) |
| `vaultwarden` | Start/stop self-hosted Vaultwarden Docker container |
| `share-port` | Cloudflare tunnel quick launcher |
| `docker-gui` | Portainer GUI launcher |

---

## 📦 Updating package lists

After installing new packages, regenerate and commit:

```bash
pacman -Qe | sort > ~/dotfiles/pkglist-pacman.txt
pacman -Qm | sort > ~/dotfiles/pkglist-aur.txt
awk '{print $1}' ~/dotfiles/pkglist-pacman.txt > ~/dotfiles/pkglist-pacman-names.txt
awk '{print $1}' ~/dotfiles/pkglist-aur.txt    > ~/dotfiles/pkglist-aur-names.txt

cd ~/dotfiles && git add pkglist-*.txt && git commit -m "chore: update package lists"
git push
```

---

## 🙈 What is NOT in this repo

| Item | Why |
|---|---|
| SSH keys (`~/.ssh/`) | Security |
| GitHub token (`gh`) | Credential manager |
| Bitwarden master password | Security |
| Syncthing device ID / keys | Generated per-device |
| rclone remote credentials | Contains API tokens |
| Browser profiles | Too large / contain sessions |
| Docker volumes | App data, not config |

---

<div align="center">
<sub>Built with ♥ on Arch Linux · Catppuccin Mocha palette</sub>
</div>
