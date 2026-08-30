#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  install.sh — One-shot Arch Linux Catppuccin Mocha Desktop Restore
#  Repo: https://github.com/ACEECA1/dotfiles
#
#  Usage:
#    git clone https://github.com/ACEECA1/dotfiles ~/dotfiles
#    cd ~/dotfiles && bash install.sh
#
#  What this does:
#    1.  System update & Pacman packages (including full TeX Live, Ruby, Math apps)
#    2.  yay (AUR helper) & AUR packages
#    3.  Oh-My-Zsh + custom plugins + Catppuccin syntax highlighting
#    4.  Symlinks all dotfiles (.config, .local/bin, desktop entries, shell configs)
#    5.  Automated AyuGram & 64Gram Telegram installations & desktop integration
#    6.  BetterDiscord injection & Catppuccin Mocha theme activation
#    7.  qBittorrent Catppuccin Mocha theme & Thunar location bar config
#    8.  Bat theme cache build & TeX Live format generation
#    9.  Fonts installation and cache update
#    10. Wallpaper setup
#    11. Copies /etc system configs (sudo)
#    12. Enables systemd user services
#    13. Sets zsh as the default shell
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOAMI="$(whoami)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()   { echo -e "${GREEN}[✓]${RESET} $*"; }
info()  { echo -e "${BLUE}[→]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; }
step()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ── Safety check ─────────────────────────────────────────────────────────────
if [[ ! -f "$DOTFILES_DIR/pkglist-pacman-names.txt" ]]; then
  error "Run this from the dotfiles directory: cd ~/dotfiles && bash install.sh"
  exit 1
fi

echo -e "${BOLD}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║   Catppuccin Mocha Desktop — Full Restore  ║"
echo "  ║   github.com/ACEECA1/dotfiles              ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Dotfiles dir : $DOTFILES_DIR"
echo "  Home dir     : $HOME"
echo ""
warn "This will install packages and link configs in ~/."
read -rp "  Continue? [y/N] " confirm
[[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 0; }

# ══════════════════════════════════════════════════════════════════════════════
step "1 — System update"
# ══════════════════════════════════════════════════════════════════════════════
info "Updating pacman databases..."
sudo pacman -Syu --noconfirm
log "System up to date"

# ══════════════════════════════════════════════════════════════════════════════
step "2 — pacman packages"
# ══════════════════════════════════════════════════════════════════════════════
info "Installing pacman packages from pkglist-pacman-names.txt..."

PACMAN_PKGS=()
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  PACMAN_PKGS+=("$pkg")
done < "$DOTFILES_DIR/pkglist-pacman-names.txt"

# Install all; pacman will skip already-installed ones (--needed)
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null \
  || warn "Some pacman packages may not exist in repos (may be AUR) — continuing"

log "pacman packages done"

# ══════════════════════════════════════════════════════════════════════════════
step "3 — yay (AUR helper)"
# ══════════════════════════════════════════════════════════════════════════════
if ! command -v yay &>/dev/null; then
  info "Installing yay..."
  sudo pacman -S --needed --noconfirm git base-devel
  TMP_YAY=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$TMP_YAY"
  (cd "$TMP_YAY" && makepkg -si --noconfirm)
  rm -rf "$TMP_YAY"
  log "yay installed"
else
  log "yay already present"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "4 — AUR packages"
# ══════════════════════════════════════════════════════════════════════════════
info "Installing AUR packages from pkglist-aur-names.txt..."

AUR_PKGS=()
while IFS= read -r pkg; do
  [[ -z "$pkg" || "$pkg" == \#* ]] && continue
  [[ "$pkg" == *-debug ]] && continue
  AUR_PKGS+=("$pkg")
done < "$DOTFILES_DIR/pkglist-aur-names.txt"

yay -S --needed --noconfirm "${AUR_PKGS[@]}" 2>/dev/null \
  || warn "Some AUR packages failed — check manually if needed"

log "AUR packages done"

# ══════════════════════════════════════════════════════════════════════════════
step "5 — Oh-My-Zsh + plugins"
# ══════════════════════════════════════════════════════════════════════════════
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh-My-Zsh..."
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  log "Oh-My-Zsh installed"
else
  log "Oh-My-Zsh already present"
fi

OMZ_CUSTOM="$HOME/.oh-my-zsh/custom"

install_plugin() {
  local name="$1" url="$2"
  local dest="$OMZ_CUSTOM/plugins/$name"
  if [[ ! -d "$dest" ]]; then
    info "Cloning zsh plugin: $name"
    git clone --depth=1 "$url" "$dest"
  else
    info "Updating zsh plugin: $name"
    git -C "$dest" pull --ff-only 2>/dev/null || true
  fi
}

install_plugin "zsh-autosuggestions"      "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting"  "https://github.com/zsh-users/zsh-syntax-highlighting"
install_plugin "zsh-completions"          "https://github.com/zsh-users/zsh-completions"
install_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting"
install_plugin "fzf-tab"                  "https://github.com/Aloxaf/fzf-tab"

mkdir -p "$OMZ_CUSTOM/plugins/catppuccin-syntax-highlighting"
if [[ -f "$DOTFILES_DIR/.config/zsh-plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]]; then
  cp "$DOTFILES_DIR/.config/zsh-plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh" \
     "$OMZ_CUSTOM/plugins/catppuccin-syntax-highlighting/"
fi

log "ZSH + plugins done"

# ══════════════════════════════════════════════════════════════════════════════
step "6 — Symlink dotfiles"
# ══════════════════════════════════════════════════════════════════════════════

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "Backing up: $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  [[ -L "$dst" ]] && rm "$dst"
  ln -s "$src" "$dst"
}

# ── Shell & home dotfiles ─────────────────────────────────────────────────────
link "$DOTFILES_DIR/.zshrc"           "$HOME/.zshrc"
link "$DOTFILES_DIR/.bashrc"          "$HOME/.bashrc"
[[ -f "$DOTFILES_DIR/.vimrc" ]] && link "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
[[ -f "$DOTFILES_DIR/.tmux.conf" ]] && link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link "$DOTFILES_DIR/.taskrc"          "$HOME/.taskrc"
link "$DOTFILES_DIR/.timewarrior.cfg" "$HOME/.timewarrior.cfg"

mkdir -p "$HOME/.calcurse"
[[ -f "$DOTFILES_DIR/.calcurse/conf" ]] && link "$DOTFILES_DIR/.calcurse/conf" "$HOME/.calcurse/conf"

mkdir -p "$HOME/.task/hooks"
[[ -f "$DOTFILES_DIR/.task/hooks/on-modify.timewarrior" ]] && link "$DOTFILES_DIR/.task/hooks/on-modify.timewarrior" "$HOME/.task/hooks/on-modify.timewarrior"

# ── ~/.config directories — symlinked wholesale ───────────────────────────────
CONFIG_DIRS=(
  alacritty atuin bat BetterDiscord broot btop cava conky copyq
  delta direnv dunst eza fastfetch fish flameshot fselect fzf
  gh-dash gitui glow gtk-3.0 gtk-4.0 i3 khal kitty lazydocker
  lazygit lf mpd mpv ncmpcpp nvim picom polybar qbittorrent
  qBittorrent rclone rofi spicetify starship superfile systemd
  tealdeer thefuck tmux xsettingsd yazi zellij zsh-plugins
)
for d in "${CONFIG_DIRS[@]}"; do
  if [[ -d "$DOTFILES_DIR/.config/$d" ]]; then
    link "$DOTFILES_DIR/.config/$d" "$HOME/.config/$d"
  fi
done

# Standalone .config files
for file in chrome-flags.conf greenclip.toml rofi-rbw.rc starship.toml; do
  if [[ -f "$DOTFILES_DIR/.config/$file" ]]; then
    link "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
  fi
done

# ── ~/.local/bin scripts ──────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR/.local/bin"/*; do
  [[ -f "$script" ]] || continue
  chmod +x "$script"
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done

# ── ~/.local/share files ──────────────────────────────────────────────────────
mkdir -p "$HOME/.local/share/applications"
for desktop in "$DOTFILES_DIR/.local/share/applications"/*.desktop; do
  [[ -f "$desktop" ]] || continue
  link "$desktop" "$HOME/.local/share/applications/$(basename "$desktop")"
done

if [[ -d "$DOTFILES_DIR/.local/share/telegram-themes" ]]; then
  mkdir -p "$HOME/.local/share/telegram-themes"
  cp -rn "$DOTFILES_DIR/.local/share/telegram-themes/." "$HOME/.local/share/telegram-themes/" 2>/dev/null || true
fi

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
log "All dotfiles symlinked"

# ══════════════════════════════════════════════════════════════════════════════
step "7 — Telegram Desktop Forks (AyuGram & 64Gram)"
# ══════════════════════════════════════════════════════════════════════════════
info "Setting up AyuGram Desktop..."
if [[ ! -f "$HOME/.local/share/AyuGram/AyuGram" ]]; then
  mkdir -p "$HOME/.local/share/AyuGram"
  AYU_TAR=$(mktemp)
  curl -sL "https://api.github.com/repos/AyuGram/AyuGramDesktop/releases/latest" \
    | grep "browser_download_url.*Linux.*\.tar\.xz" | cut -d : -f 2,3 | tr -d \" | tr -d ' ' | head -n 1 \
    | xargs -I{} curl -fSL "{}" -o "$AYU_TAR" 2>/dev/null || true
  if [[ -f "$AYU_TAR" && -s "$AYU_TAR" ]]; then
    tar -xf "$AYU_TAR" -C "$HOME/.local/share/AyuGram/" 2>/dev/null || true
    rm -f "$AYU_TAR"
  fi
fi

info "Setting up 64Gram Desktop..."
if [[ ! -f "$HOME/.local/share/64Gram/64Gram" ]]; then
  mkdir -p "$HOME/.local/share/64Gram"
  X64_TAR=$(mktemp)
  curl -sL "https://api.github.com/repos/TDesktop-x64/tdesktop/releases/latest" \
    | grep "browser_download_url.*linux.*\.tar\.xz" | cut -d : -f 2,3 | tr -d \" | tr -d ' ' | head -n 1 \
    | xargs -I{} curl -fSL "{}" -o "$X64_TAR" 2>/dev/null || true
  if [[ -f "$X64_TAR" && -s "$X64_TAR" ]]; then
    tar -xf "$X64_TAR" -C "$HOME/.local/share/64Gram/" 2>/dev/null || true
    rm -f "$X64_TAR"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
step "8 — App Configurations & Catppuccin Mocha Hooks"
# ══════════════════════════════════════════════════════════════════════════════
# Thunar Location Entry
if command -v xfconf-query &>/dev/null; then
  xfconf-query -c thunar -p /last-location-bar -s "ThunarLocationEntry" --create -t string 2>/dev/null || true
  log "Thunar location entry enabled"
fi

# Bat theme cache
if command -v bat &>/dev/null; then
  bat cache --build 2>/dev/null || true
  log "Bat cache built with Catppuccin Mocha"
fi

# TeX Live formats
if command -v fmtutil-user &>/dev/null; then
  fmtutil-user --all 2>/dev/null || true
  log "TeX Live formats generated"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "9 — Fonts"
# ══════════════════════════════════════════════════════════════════════════════
FONT_DST="$HOME/.local/share/fonts"
mkdir -p "$FONT_DST"
if [[ -d "$DOTFILES_DIR/.local/share/fonts" ]]; then
  info "Copying bundled fonts..."
  cp -rn "$DOTFILES_DIR/.local/share/fonts/." "$FONT_DST/" 2>/dev/null || true
  fc-cache -fv "$FONT_DST" &>/dev/null
  log "Fonts installed and cache updated"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "10 — Wallpaper"
# ══════════════════════════════════════════════════════════════════════════════
mkdir -p "$HOME/Pictures"
if [[ -f "$DOTFILES_DIR/wallpaper.jpg" ]]; then
  cp -n "$DOTFILES_DIR/wallpaper.jpg" "$HOME/Pictures/catppuccin-wall-dark.jpg" 2>/dev/null || true
  log "Wallpaper → ~/Pictures/catppuccin-wall-dark.jpg"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "11 — /etc system configs"
# ══════════════════════════════════════════════════════════════════════════════
info "Copying system configs to /etc (sudo required)..."

safe_etc() {
  local src="$1" dst="$2"
  sudo mkdir -p "$(dirname "$dst")"
  [[ -f "$dst" ]] && sudo cp "$dst" "$dst.bak" && warn "Backed up $dst"
  sudo cp "$src" "$dst"
  log "Installed /etc: $(basename "$dst")"
}

if [[ -f "$DOTFILES_DIR/etc/sddm.conf.d/theme.conf" ]]; then
  safe_etc "$DOTFILES_DIR/etc/sddm.conf.d/theme.conf"             "/etc/sddm.conf.d/theme.conf"
fi
if [[ -f "$DOTFILES_DIR/etc/sysctl.d/99-performance.conf" ]]; then
  safe_etc "$DOTFILES_DIR/etc/sysctl.d/99-performance.conf"       "/etc/sysctl.d/99-performance.conf"
fi
if [[ -f "$DOTFILES_DIR/etc/default/cpupower" ]]; then
  safe_etc "$DOTFILES_DIR/etc/default/cpupower"                   "/etc/default/cpupower"
fi
if [[ -f "$DOTFILES_DIR/etc/systemd/logind.conf.d/nosleep.conf" ]]; then
  safe_etc "$DOTFILES_DIR/etc/systemd/logind.conf.d/nosleep.conf" "/etc/systemd/logind.conf.d/nosleep.conf"
fi

sudo sysctl --system &>/dev/null || true
log "/etc configs applied"

# ══════════════════════════════════════════════════════════════════════════════
step "12 — Systemd user services"
# ══════════════════════════════════════════════════════════════════════════════
systemctl --user daemon-reload 2>/dev/null || true
for svc in copyq i3-autoname mpd syncthing wireplumber; do
  if systemctl --user enable "$svc" 2>/dev/null; then
    log "Enabled: $svc"
  else
    warn "Could not enable $svc (needs graphical session; run manually after login)"
  fi
done

# ══════════════════════════════════════════════════════════════════════════════
step "13 — Default shell → zsh"
# ══════════════════════════════════════════════════════════════════════════════
ZSH_PATH="$(command -v zsh || echo '/bin/zsh')"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  info "Setting default shell to zsh..."
  sudo chsh -s "$ZSH_PATH" "$WHOAMI"
  log "Default shell → zsh (takes effect on next login)"
else
  log "zsh is already the default shell"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "14 — XDG user dirs"
# ══════════════════════════════════════════════════════════════════════════════
xdg-user-dirs-update 2>/dev/null && log "XDG dirs updated" || true

# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════╗"
echo                "║   ✅  Install complete!           ║"
echo -e             "╚══════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}  Manual steps after reboot:${RESET}"
echo "  ① Reboot now:           sudo reboot"
echo "  ② GitHub CLI:           gh auth login"
echo "  ③ Bitwarden:            rbw login  (or bw login)"
echo "  ④ SSH keys:             ssh-keygen -t ed25519 -C 'your@email'"
echo "  ⑤ HDD routing:         hdd-route all   (if HDD is mounted)"
echo ""
echo -e "${BOLD}  Quick reference:${RESET}"
echo "  TOOLS_GUIDE.md  — full keybinding & tool docs"
echo "  tldr <tool>     — quick cheatsheet for any command"
echo ""
