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
#    1.  Installs base packages via pacman
#    2.  Installs yay (AUR helper) if missing, then AUR packages
#    3.  Installs Oh-My-Zsh + custom plugins
#    4.  Symlinks all dotfiles to their proper locations
#    5.  Installs bundled fonts and wallpaper
#    6.  Copies /etc system configs (sudo)
#    7.  Enables systemd user services
#    8.  Sets zsh as the default shell
#
#  NOT included (do manually after):
#    - gh auth login  (GitHub CLI token)
#    - SSH keys       (copy from backup or generate fresh)
#    - Bitwarden/rbw  (re-authenticate)
#    - Syncthing      (re-pair devices)
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
warn "This will install ~300 packages and overwrite configs in ~/."
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
  [[ "$pkg" == *-debug ]] && continue   # skip auto-generated debug packages
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

# Catppuccin Mocha syntax highlight theme — bundled in repo (3 kB)
mkdir -p "$OMZ_CUSTOM/plugins/catppuccin-syntax-highlighting"
cp "$DOTFILES_DIR/.config/zsh-plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh" \
   "$OMZ_CUSTOM/plugins/catppuccin-syntax-highlighting/"

log "ZSH + plugins done"

# ══════════════════════════════════════════════════════════════════════════════
step "6 — Symlink dotfiles"
# ══════════════════════════════════════════════════════════════════════════════

# Symlink helper: backs up any real file before linking
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
link "$DOTFILES_DIR/.taskrc"          "$HOME/.taskrc"
link "$DOTFILES_DIR/.timewarrior.cfg" "$HOME/.timewarrior.cfg"

mkdir -p "$HOME/.calcurse"
link "$DOTFILES_DIR/.calcurse/conf"   "$HOME/.calcurse/conf"

mkdir -p "$HOME/.task/hooks"
link "$DOTFILES_DIR/.task/hooks/on-modify.timewarrior" \
     "$HOME/.task/hooks/on-modify.timewarrior"

# ── ~/.config directories — symlinked wholesale ───────────────────────────────
CONFIG_DIRS=(
  alacritty atuin broot btop cava conky copyq direnv dunst fish
  flameshot fselect gh-dash gitui glow i3 khal kitty lazydocker
  lazygit lf mpd ncmpcpp nvim picom polybar rofi starship
  systemd tealdeer thefuck tmux xsettingsd zellij
)
for d in "${CONFIG_DIRS[@]}"; do
  link "$DOTFILES_DIR/.config/$d" "$HOME/.config/$d"
done

# Standalone .config files/dirs
link "$DOTFILES_DIR/.config/chrome-flags.conf" "$HOME/.config/chrome-flags.conf"
link "$DOTFILES_DIR/.config/greenclip.toml"    "$HOME/.config/greenclip.toml"
link "$DOTFILES_DIR/.config/rofi-rbw.rc"       "$HOME/.config/rofi-rbw.rc"
link "$DOTFILES_DIR/.config/gtk-3.0"           "$HOME/.config/gtk-3.0"
link "$DOTFILES_DIR/.config/gtk-4.0"           "$HOME/.config/gtk-4.0"

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

mkdir -p "$HOME/.local/share/navi/cheats"
link "$DOTFILES_DIR/.local/share/navi/cheats/walid-arch.cheat" \
     "$HOME/.local/share/navi/cheats/walid-arch.cheat"

mkdir -p "$HOME/.local/share/tealdeer/pages/common"
for pg in "$DOTFILES_DIR/.local/share/tealdeer/pages"/*.md; do
  [[ -f "$pg" ]] || continue
  link "$pg" "$HOME/.local/share/tealdeer/pages/$(basename "$pg")"
done
for pg in "$DOTFILES_DIR/.local/share/tealdeer/pages/common"/*.md; do
  [[ -f "$pg" ]] || continue
  link "$pg" "$HOME/.local/share/tealdeer/pages/common/$(basename "$pg")"
done

log "All dotfiles symlinked"

# ══════════════════════════════════════════════════════════════════════════════
step "7 — Fonts"
# ══════════════════════════════════════════════════════════════════════════════
FONT_DST="$HOME/.local/share/fonts"
mkdir -p "$FONT_DST"
info "Copying bundled fonts..."
cp -rn "$DOTFILES_DIR/.local/share/fonts/." "$FONT_DST/" 2>/dev/null || true
fc-cache -fv "$FONT_DST" &>/dev/null
log "Fonts installed and cache updated"

# ══════════════════════════════════════════════════════════════════════════════
step "8 — Wallpaper"
# ══════════════════════════════════════════════════════════════════════════════
mkdir -p "$HOME/Pictures"
cp -n "$DOTFILES_DIR/wallpaper.jpg" "$HOME/Pictures/catppuccin-wall-dark.jpg" 2>/dev/null || true
log "Wallpaper → ~/Pictures/catppuccin-wall-dark.jpg"

# ══════════════════════════════════════════════════════════════════════════════
step "9 — /etc system configs"
# ══════════════════════════════════════════════════════════════════════════════
info "Copying system configs to /etc (sudo required)..."

safe_etc() {
  local src="$1" dst="$2"
  sudo mkdir -p "$(dirname "$dst")"
  [[ -f "$dst" ]] && sudo cp "$dst" "$dst.bak" && warn "Backed up $dst"
  sudo cp "$src" "$dst"
  log "Installed /etc: $(basename "$dst")"
}

safe_etc "$DOTFILES_DIR/etc/sddm.conf.d/theme.conf"             "/etc/sddm.conf.d/theme.conf"
safe_etc "$DOTFILES_DIR/etc/sysctl.d/99-performance.conf"       "/etc/sysctl.d/99-performance.conf"
safe_etc "$DOTFILES_DIR/etc/default/cpupower"                   "/etc/default/cpupower"
safe_etc "$DOTFILES_DIR/etc/systemd/logind.conf.d/nosleep.conf" "/etc/systemd/logind.conf.d/nosleep.conf"

# fstab: show diff and ask before overwriting (dangerous)
echo ""
warn "fstab — showing diff (NOT auto-applied — verify UUIDs match your hardware):"
diff "$DOTFILES_DIR/etc/fstab" /etc/fstab 2>/dev/null || true
read -rp "  Apply dotfiles fstab to /etc/fstab? [y/N] " apply_fstab
if [[ "${apply_fstab,,}" == "y" ]]; then
  safe_etc "$DOTFILES_DIR/etc/fstab" "/etc/fstab"
else
  warn "Skipped fstab — update /etc/fstab manually with correct UUIDs (blkid)"
fi

sudo sysctl --system &>/dev/null
log "/etc configs applied"

# ══════════════════════════════════════════════════════════════════════════════
step "10 — Systemd user services"
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
step "11 — Default shell → zsh"
# ══════════════════════════════════════════════════════════════════════════════
ZSH_PATH="$(command -v zsh)"
if [[ "$SHELL" != "$ZSH_PATH" ]]; then
  info "Setting default shell to zsh..."
  sudo chsh -s "$ZSH_PATH" "$WHOAMI"
  log "Default shell → zsh (takes effect on next login)"
else
  log "zsh is already the default shell"
fi

# ══════════════════════════════════════════════════════════════════════════════
step "12 — XDG user dirs"
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
echo "  ⑥ Mise runtimes:        mise install    (node/python/go/java)"
echo "  ⑦ Rclone remotes:       rclone config"
echo "  ⑧ Syncthing:            open browser → localhost:8384"
echo ""
echo -e "${BOLD}  Quick reference:${RESET}"
echo "  TOOLS_GUIDE.md  — full keybinding & tool docs"
echo "  tldr <tool>     — quick cheatsheet for any command"
echo ""
