#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  install.sh — Arch Linux Catppuccin Mocha Desktop Restore & Setup Engine
#  Repo: https://github.com/ACEECA1/dotfiles
#
#  Usage:
#    bash install.sh [OPTIONS]
#
#  Options:
#    -y, --all, --full      Install everything automatically (Accept all)
#    -i, --custom           Interactive mode: choose which tools & categories to install
#    -d, --dotfiles-only    Only symlink configs & dotfiles (Refuse all package downloads)
#    -h, --help             Show help documentation
#
#  What this handles:
#    1.  System update & Pacman packages (modular: TeX Live, Math, SongRec/Shazam)
#    2.  yay (AUR helper) & AUR packages
#    3.  Oh-My-Zsh + custom plugins + Catppuccin syntax highlighting
#    4.  Symlinks dotfiles (.config, .local/bin, desktop entries, icons, shell configs)
#    5.  Native C & Rust desktop helpers compilation & audio monitor configuration:
#        - x11-grab-probe (C X11 grab diagnostic)
#        - portal-remember-dir (GTK3 portal directory memory library)
#        - scratchpad_override (C X11 fullscreen override library)
#        - Rust daemons (desktop-music-daemon, autoname-workspaces, rofi-clipboard,
#                        sync-antigravity, mpris-live)
#        - SongRec / Shazam audio monitor loopback setup
#    6.  Automated AyuGram & 64Gram Telegram installations & desktop integration
#    7.  BetterDiscord injection & Catppuccin Mocha theme activation
#    8.  qBittorrent theme, Thunar location bar, Bat cache, TeX Live formats
#    9.  Mise polyglot toolchains restoration
#    10. Fonts installation and cache update
#    11. Wallpaper setup
#    12. System configs in /etc (sudo)
#    13. Enables systemd user services
#    14. Sets zsh as the default shell
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOAMI="$(whoami)"

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; RESET='\033[0m'

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

# ── Usage / Help ─────────────────────────────────────────────────────────────
show_help() {
  echo -e "${BOLD}${MAGENTA}Catppuccin Mocha Desktop Restore Engine${RESET}
Repository: https://github.com/ACEECA1/dotfiles

${BOLD}USAGE:${RESET}
  bash install.sh [OPTIONS]

${BOLD}OPTIONS:${RESET}
  ${GREEN}-y, --all, --full${RESET}      Install everything automatically without prompts (Accept all)
  ${GREEN}-i, --custom${RESET}           Interactive mode: choose which tools and components to install
  ${GREEN}-d, --dotfiles-only${RESET}    Only symlink configuration files in ~/.config and ~/.local (Refuse packages)
  ${GREEN}-h, --help${RESET}             Show this help message and exit

${BOLD}INTERACTIVE MENU:${RESET}
  Running without arguments opens an interactive mode selection menu where you can:
  • Accept all tools & packages
  • Selectively accept or refuse individual tools (TeX Live, SongRec, Telegram forks, etc.)
  • Refuse all package downloads and only link dotfiles"
  exit 0
}

# ── CLI Arguments Parsing ─────────────────────────────────────────────────────
INSTALL_MODE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--all|--full|--yes)
      INSTALL_MODE="all"
      shift
      ;;
    -i|--custom|--interactive)
      INSTALL_MODE="custom"
      shift
      ;;
    -d|--dotfiles-only)
      INSTALL_MODE="dotfiles"
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      error "Unknown option: $1"
      echo "Run './install.sh --help' for usage."
      exit 1
      ;;
  esac
done

# ── Interactive Mode Banner ──────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║      Catppuccin Mocha Desktop — Restore Engine       ║"
echo "  ║      github.com/ACEECA1/dotfiles                     ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  Dotfiles directory : $DOTFILES_DIR"
echo "  Target home        : $HOME"
echo ""

if [[ -z "$INSTALL_MODE" ]]; then
  echo -e "${BOLD}${CYAN}Select installation mode:${RESET}"
  echo -e "  ${BOLD}[1] All (Full Restore)${RESET}   — Install all packages, tools, and configs automatically"
  echo -e "  ${BOLD}[2] Custom (Interactive)${RESET}  — Choose which tools and categories to install or refuse"
  echo -e "  ${BOLD}[3] Dotfiles Only${RESET}         — Symlink configs only (Skip all package & binary downloads)"
  echo -e "  ${BOLD}[q] Quit${RESET}                  — Abort installer without making any changes"
  echo ""
  read -rp "  Enter choice [1/2/3/q, default: 1]: " mode_choice || true
  case "${mode_choice,,}" in
    1|""|"a"|"all")
      INSTALL_MODE="all"
      ;;
    2|"c"|"custom"|"i")
      INSTALL_MODE="custom"
      ;;
    3|"d"|"dotfiles"|"dotfiles-only")
      INSTALL_MODE="dotfiles"
      ;;
    q|"quit"|"exit")
      echo "Installation cancelled."
      exit 0
      ;;
    *)
      warn "Unknown choice '$mode_choice'; defaulting to [2] Custom."
      INSTALL_MODE="custom"
      ;;
  esac
fi

log "Active mode: ${BOLD}${INSTALL_MODE^^}${RESET}"

# ── Interactive Prompt Helper ────────────────────────────────────────────────
# Returns 0 for Yes, 1 for No.
# Under "all" mode, always returns 0 (Yes).
# Under "dotfiles" mode, always returns 1 (No) for non-dotfile steps.
prompt_yn() {
  local prompt_text="$1"
  local default_val="${2:-y}"

  if [[ "$INSTALL_MODE" == "all" ]]; then
    return 0
  fi
  if [[ "$INSTALL_MODE" == "dotfiles" ]]; then
    return 1
  fi

  local choices="[Y/n]"
  [[ "$default_val" == "n" ]] && choices="[y/N]"

  local resp=""
  echo -ne "  ${BOLD}${YELLOW}?${RESET} ${prompt_text} ${CYAN}${choices}${RESET} "
  read -r resp || true
  resp="${resp:-$default_val}"
  if [[ "${resp,,}" == "y"* ]]; then
    return 0
  else
    return 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Storage Layout Configuration (Single Drive vs Multi-Drive)
# ══════════════════════════════════════════════════════════════════════════════
mkdir -p "$HOME/.config"

if [[ "$INSTALL_MODE" == "dotfiles" ]]; then
  if [[ ! -f "$HOME/.config/dotfiles-storage.env" ]]; then
    cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
  fi
elif [[ "$INSTALL_MODE" == "all" ]]; then
  if [[ ! -f "$HOME/.config/dotfiles-storage.env" ]]; then
    cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
    log "Default single-drive storage layout configured"
  fi
else
  # Custom / Interactive storage configuration
  echo ""
  echo -e "${BOLD}${CYAN}══ Storage Layout Configuration ══${RESET}"
  echo "  [1] Single Drive (Default) — Store all caches, toolchains, and data on primary drive"
  echo "  [2] Multi-Drive Routing    — Route heavy caches and toolchains to a secondary drive (HDD/SSD)"
  read -rp "  Select storage layout [1/2, default: 1]: " storage_choice || true
  storage_choice="${storage_choice:-1}"

  if [[ "$storage_choice" == "2" ]]; then
    echo ""
    echo "Available storage mount points:"
    df -h | grep -E '^/dev/' || true
    echo ""
    read -rp "  Enter secondary drive mount path (e.g. /mnt/drive2, /mnt/storage): " user_hdd || true
    read -rp "  Enter optional data drive mount path (e.g. /mnt/drive3, press Enter to use same): " user_data || true
    user_data="${user_data:-$user_hdd}"

    cat > "$HOME/.config/dotfiles-storage.env" << EOF
# Dotfiles secondary storage routing
export HDD_MOUNT="$user_hdd"
export DATA_MOUNT="$user_data"
EOF
    log "Storage configuration saved → ~/.config/dotfiles-storage.env"
  else
    cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
    log "Single-drive layout configured"
  fi
fi

# Load storage environment if present
[[ -f "$HOME/.config/dotfiles-storage.env" ]] && source "$HOME/.config/dotfiles-storage.env"

# ══════════════════════════════════════════════════════════════════════════════
# Step 1 — System Update
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "1 — System update"
  if prompt_yn "Run full system update (sudo pacman -Syu)?" "y"; then
    info "Updating pacman databases and upgrading packages..."
    sudo pacman -Syu --noconfirm
    log "System is up to date"
  else
    warn "Skipped system update"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 2 — Pacman Packages
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "2 — Pacman packages"
  if prompt_yn "Install system packages from pkglist-pacman-names.txt?" "y"; then
    INSTALL_TEXLIVE="y"
    INSTALL_MATH="y"
    INSTALL_SONGREC="y"

    if [[ "$INSTALL_MODE" == "custom" ]]; then
      echo -e "\n  ${BOLD}${CYAN}Granular Tool Selection:${RESET}"
      if ! prompt_yn "  Include TeX Live document suite (~3GB)?" "y"; then
        INSTALL_TEXLIVE="n"
        warn "  TeX Live excluded from package list"
      fi
      if ! prompt_yn "  Include Math & CAS applications (Cantor, LabPlot, Kig, Maxima)?" "y"; then
        INSTALL_MATH="n"
        warn "  Math/CAS applications excluded from package list"
      fi
      if ! prompt_yn "  Include SongRec / Shazam audio identifier?" "y"; then
        INSTALL_SONGREC="n"
        warn "  SongRec excluded from package list"
      fi
    fi

    info "Reading packages from pkglist-pacman-names.txt..."
    PACMAN_PKGS=()
    while IFS= read -r pkg; do
      [[ -z "$pkg" || "$pkg" == \#* ]] && continue
      # Filter TeX Live if refused
      if [[ "$INSTALL_TEXLIVE" == "n" && "$pkg" == texlive* ]]; then
        continue
      fi
      # Filter Math apps if refused
      if [[ "$INSTALL_MATH" == "n" ]] && [[ "$pkg" =~ ^(cantor|kig|kmplot|labplot|maxima)$ ]]; then
        continue
      fi
      # Filter SongRec if refused
      if [[ "$INSTALL_SONGREC" == "n" && "$pkg" == "songrec" ]]; then
        continue
      fi
      PACMAN_PKGS+=("$pkg")
    done < "$DOTFILES_DIR/pkglist-pacman-names.txt"

    info "Installing ${#PACMAN_PKGS[@]} pacman packages..."
    sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" 2>/dev/null \
      || warn "Some pacman packages may not exist in repos (may be AUR) — continuing"
    log "Pacman packages installed"
  else
    warn "Skipped pacman packages installation"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 3 — yay (AUR Helper)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "3 — yay (AUR helper)"
  if command -v yay &>/dev/null; then
    log "yay is already installed"
  elif prompt_yn "Install yay AUR helper?" "y"; then
    info "Installing yay prerequisites (base-devel, git)..."
    sudo pacman -S --needed --noconfirm git base-devel
    TMP_YAY=$(mktemp -d)
    info "Cloning and building yay..."
    git clone https://aur.archlinux.org/yay.git "$TMP_YAY"
    (cd "$TMP_YAY" && makepkg -si --noconfirm)
    rm -rf "$TMP_YAY"
    log "yay installed successfully"
  else
    warn "Skipped yay installation"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 4 — AUR Packages
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "4 — AUR packages"
  if command -v yay &>/dev/null; then
    if prompt_yn "Install AUR packages from pkglist-aur-names.txt?" "y"; then
      info "Installing AUR packages..."
      AUR_PKGS=()
      while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        [[ "$pkg" == *-debug ]] && continue
        AUR_PKGS+=("$pkg")
      done < "$DOTFILES_DIR/pkglist-aur-names.txt"

      yay -S --needed --noconfirm "${AUR_PKGS[@]}" 2>/dev/null \
        || warn "Some AUR packages failed — check manually if needed"
      log "AUR packages done"
    else
      warn "Skipped AUR packages installation"
    fi
  else
    warn "yay not present — skipping AUR packages"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 5 — Oh-My-Zsh + Plugins
# ══════════════════════════════════════════════════════════════════════════════
step "5 — Oh-My-Zsh + plugins"
if prompt_yn "Install Oh-My-Zsh and custom zsh plugins?" "y"; then
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    info "Installing Oh-My-Zsh..."
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    log "Oh-My-Zsh installed"
  else
    log "Oh-My-Zsh is already present"
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
  log "Zsh plugins configured"
else
  warn "Skipped Oh-My-Zsh and plugins"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 6 — Symlink Dotfiles
# ══════════════════════════════════════════════════════════════════════════════
step "6 — Symlink dotfiles"

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

if [[ "$INSTALL_MODE" == "dotfiles" ]] || prompt_yn "Symlink dotfiles (.config, .local/bin, desktop entries)?" "y"; then
  # ── Shell & home dotfiles ───────────────────────────────────────────────────
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

  # ── Storage Drives & Personal Symlinks ─────────────────────────────────────
  if [[ -n "${HDD_MOUNT:-}" && -d "$HDD_MOUNT" ]]; then
    link "$HDD_MOUNT" "$HOME/D"
  elif [[ -d "/mnt/drive2" ]]; then
    link "/mnt/drive2" "$HOME/D"
  fi

  if [[ -n "${DATA_MOUNT:-}" && -d "$DATA_MOUNT" ]]; then
    link "$DATA_MOUNT" "$HOME/E"
    [[ -d "$DATA_MOUNT/Coding" ]] && link "$DATA_MOUNT/Coding" "$HOME/Coding"
    [[ -d "$DATA_MOUNT/Pictures" ]] && link "$DATA_MOUNT/Pictures" "$HOME/Pictures"
    [[ -d "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" ]] && link "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" "$HOME/Downloads/Telegram Desktop"
  elif [[ -d "/mnt/drive3" ]]; then
    link "/mnt/drive3" "$HOME/E"
    [[ -d "/mnt/drive3/Coding" ]] && link "/mnt/drive3/Coding" "$HOME/Coding"
    [[ -d "/mnt/drive3/Pictures" ]] && link "/mnt/drive3/Pictures" "$HOME/Pictures"
    [[ -d "/mnt/drive3/Backups/ArchLinuxData/TelegramDesktop" ]] && link "/mnt/drive3/Backups/ArchLinuxData/TelegramDesktop" "$HOME/Downloads/Telegram Desktop"
  fi

  # ── ~/.config directories — symlinked wholesale ─────────────────────────────
  CONFIG_DIRS=(
    alacritty atuin bat BetterDiscord broot btop cava conky copyq
    delta direnv dunst eza fastfetch fish flameshot fselect fzf
    gh-dash gitui glow gtk-3.0 gtk-4.0 i3 khal kitty lazydocker
    lazygit lf mise mpd mpv ncmpcpp nvim picom polybar qbittorrent
    qBittorrent rclone rofi songrec spicetify starship superfile systemd
    tealdeer thefuck Thunar tmux tumbler xfce4 xsettingsd yazi zellij zsh-plugins
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

  # ── ~/.local/bin scripts ────────────────────────────────────────────────────
  mkdir -p "$HOME/.local/bin"
  for script in "$DOTFILES_DIR/.local/bin"/*; do
    [[ -f "$script" || -L "$script" ]] || continue
    chmod +x "$script" 2>/dev/null || true
    link "$script" "$HOME/.local/bin/$(basename "$script")"
  done

  # ── ~/.local/src source directories ─────────────────────────────────────────
  if [[ -d "$DOTFILES_DIR/.local/src" ]]; then
    mkdir -p "$HOME/.local/src"
    cp -rn "$DOTFILES_DIR/.local/src/." "$HOME/.local/src/" 2>/dev/null || true
  fi

  # ── ~/.local/share files & desktop entries ──────────────────────────────────
  mkdir -p "$HOME/.local/share/applications"
  for desktop in "$DOTFILES_DIR/.local/share/applications"/*.desktop; do
    [[ -f "$desktop" ]] || continue
    link "$desktop" "$HOME/.local/share/applications/$(basename "$desktop")"
  done

  # Application icons (e.g. SongRec, Shazam)
  if [[ -d "$DOTFILES_DIR/.local/share/icons" ]]; then
    mkdir -p "$HOME/.local/share/icons"
    cp -rn "$DOTFILES_DIR/.local/share/icons/." "$HOME/.local/share/icons/" 2>/dev/null || true
  fi

  if [[ -d "$DOTFILES_DIR/.local/share/telegram-themes" ]]; then
    mkdir -p "$HOME/.local/share/telegram-themes"
    cp -rn "$DOTFILES_DIR/.local/share/telegram-themes/." "$HOME/.local/share/telegram-themes/" 2>/dev/null || true
  fi

  if [[ -d "$DOTFILES_DIR/.local/share/navi" ]]; then
    mkdir -p "$HOME/.local/share/navi/cheats"
    cp -rn "$DOTFILES_DIR/.local/share/navi/cheats/." "$HOME/.local/share/navi/cheats/" 2>/dev/null || true
    log "Navi interactive cheatsheets installed"
  fi

  # ── Custom Zsh completions ─────────────────────────────────────────────────
  if [[ -d "$DOTFILES_DIR/.zsh/completions" ]]; then
    mkdir -p "$HOME/.zsh/completions"
    cp -rn "$DOTFILES_DIR/.zsh/completions/." "$HOME/.zsh/completions/" 2>/dev/null || true
    log "Custom Zsh completions installed"
  fi

  # Adjust systemd user service paths if user home differs from /home/walid
  if [[ "$HOME" != "/home/walid" && -d "$HOME/.config/systemd/user" ]]; then
    info "Adjusting systemd user service paths for $USER..."
    find "$HOME/.config/systemd/user" -type f \( -name "*.service" -o -name "*.conf" \) \
      -exec sed -i "s|/home/walid|$HOME|g" {} + 2>/dev/null || true
  fi

  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  log "All dotfiles symlinked"
else
  warn "Skipped dotfiles symlinking"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 7 — Native C & Rust Desktop Tools Compilation
# ══════════════════════════════════════════════════════════════════════════════
step "7 — Native C & Rust desktop tools"
if prompt_yn "Compile and install native desktop tools (C helpers & Rust daemons)?" "y"; then
  mkdir -p "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/src"

  # ── 1. C Tools & Libraries ──────────────────────────────────────────────────
  if command -v gcc &>/dev/null; then
    # x11-grab-probe (X11 grab detector)
    if [[ -d "$HOME/.local/src/x11-grab-probe" ]]; then
      info "Compiling x11-grab-probe (C)..."
      gcc -O2 "$HOME/.local/src/x11-grab-probe/x11-grab-probe.c" -o "$HOME/.local/bin/x11-grab-probe" -lX11 2>/dev/null || true
      chmod +x "$HOME/.local/bin/x11-grab-probe" 2>/dev/null || true
      log "x11-grab-probe installed → ~/.local/bin/x11-grab-probe"
    fi

    # portal-remember-dir (GTK3 file chooser directory recall library)
    if [[ -d "$HOME/.local/src/portal-remember-dir" ]] && pkg-config --exists gtk+-3.0 2>/dev/null; then
      info "Compiling portal-remember-dir (C shared library)..."
      gcc -shared -fPIC -O2 "$HOME/.local/src/portal-remember-dir/portal-remember-dir.c" \
        -o "$HOME/.local/lib/libportal-remember-dir.so" $(pkg-config --cflags --libs gtk+-3.0) -ldl 2>/dev/null || true
      log "libportal-remember-dir.so installed → ~/.local/lib/libportal-remember-dir.so"
    fi

    # scratchpad_override (Fullscreen scratchpad helper library)
    if [[ -f "$DOTFILES_DIR/.local/lib/scratchpad_override.c" ]]; then
      cp "$DOTFILES_DIR/.local/lib/scratchpad_override.c" "$HOME/.local/lib/"
      gcc -shared -fPIC -O2 "$HOME/.local/lib/scratchpad_override.c" -o "$HOME/.local/lib/libscratchpad_override.so" -ldl -lX11 2>/dev/null || true
      log "libscratchpad_override.so installed → ~/.local/lib/libscratchpad_override.so"
    fi
  else
    warn "gcc not found — skipping C helpers compilation"
  fi

  # ── 2. Rust Desktop Daemons ─────────────────────────────────────────────────
  if command -v cargo &>/dev/null; then
    for pkg in desktop-music-daemon autoname-workspaces rofi-clipboard sync-antigravity mpris-live; do
      if [[ -d "$HOME/.local/src/$pkg" ]]; then
        info "Compiling $pkg (Rust)..."
        cargo build --release --manifest-path "$HOME/.local/src/$pkg/Cargo.toml" 2>/dev/null || true
        if [[ -f "$HOME/.local/src/$pkg/target/release/$pkg" ]]; then
          cp "$HOME/.local/src/$pkg/target/release/$pkg" "$HOME/.local/bin/$pkg"
          chmod +x "$HOME/.local/bin/$pkg"
          log "Compiled and installed $pkg → ~/.local/bin/$pkg"
        fi
      fi
    done
  else
    warn "cargo not found — skipping Rust daemons compilation"
  fi

  # ── 3. SongRec Audio Monitor Loopback Configuration ──────────────────────────
  if command -v pactl &>/dev/null && [[ -f "$HOME/.config/songrec/preferences.toml" ]]; then
    DEFAULT_SINK="$(pactl get-default-sink 2>/dev/null || true)"
    if [[ -n "$DEFAULT_SINK" ]]; then
      MONITOR_DEV="${DEFAULT_SINK}.monitor"
      sed -i "s|^current_device_name = .*|current_device_name = \"$MONITOR_DEV\"|" "$HOME/.config/songrec/preferences.toml" 2>/dev/null || true
      log "SongRec default audio monitor configured → $MONITOR_DEV"
    fi
  fi
else
  warn "Skipped native desktop tools compilation"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 8 — Telegram Desktop Forks (AyuGram & 64Gram)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "8 — Telegram Desktop Forks (AyuGram & 64Gram)"
  if prompt_yn "Download and configure Telegram Desktop forks (AyuGram / 64Gram)?" "y"; then
    # AyuGram
    if prompt_yn "  Install AyuGram Desktop?" "y"; then
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
          log "AyuGram Desktop installed"
        fi
      else
        log "AyuGram Desktop already present"
      fi
    fi

    # 64Gram
    if prompt_yn "  Install 64Gram Desktop?" "y"; then
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
          log "64Gram Desktop installed"
        fi
      else
        log "64Gram Desktop already present"
      fi
    fi
  else
    warn "Skipped Telegram Desktop forks"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 9 — App Configurations & Catppuccin Mocha Hooks
# ══════════════════════════════════════════════════════════════════════════════
step "9 — App Configurations & Catppuccin Mocha Hooks"

# BetterDiscord injection into Discord
DISCORD_CORE=$(find "$HOME/.config/discord" -name "discord_desktop_core" -type d 2>/dev/null | head -1 || true)
if [[ -n "$DISCORD_CORE" && -f "$DISCORD_CORE/index.js" ]]; then
  if prompt_yn "Inject BetterDiscord into Discord core?" "y"; then
    if ! grep -q "betterdiscord.asar" "$DISCORD_CORE/index.js"; then
      echo "require('$HOME/.config/BetterDiscord/data/betterdiscord.asar');" | cat - "$DISCORD_CORE/index.js" > "$DISCORD_CORE/index.js.tmp" && mv "$DISCORD_CORE/index.js.tmp" "$DISCORD_CORE/index.js"
      log "BetterDiscord injected into Discord core"
    fi
  fi
fi

# Git Delta Catppuccin Include
if [[ -f "$HOME/.config/delta/catppuccin.gitconfig" ]]; then
  git config --global include.path "$HOME/.config/delta/catppuccin.gitconfig" 2>/dev/null || true
  log "Git Delta Catppuccin theme registered"
fi

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

# Secondary drive cache routing (if configured and mounted)
if [[ -f "$HOME/.config/dotfiles-storage.env" ]]; then
  source "$HOME/.config/dotfiles-storage.env"
fi

ACTIVE_HDD="${HDD_MOUNT:-/mnt/drive2}"
if [[ -n "$ACTIVE_HDD" && -d "$ACTIVE_HDD" ]] && command -v hdd-route &>/dev/null; then
  info "Applying secondary drive routing for developer caches and toolchains..."
  hdd-route all 2>/dev/null || true
  log "Secondary drive routing configured"
fi

# Polyglot runtime restoration via mise
if command -v mise &>/dev/null; then
  if prompt_yn "Restore polyglot toolchains via mise?" "y"; then
    info "Restoring polyglot runtimes via mise..."
    export MISE_DATA_DIR="${ACTIVE_HDD:-$HOME}/.mise"
    export MISE_CACHE_DIR="${ACTIVE_HDD:-$HOME}/.cache/mise"
    mise install -y 2>/dev/null || true
    log "Mise polyglot toolchains restored"
  fi
fi

# Pre-compile zsh completion dumps to bytecode
if command -v zsh &>/dev/null; then
  zsh -c 'for f in ~/.zcompdump*; do zcompile "$f" 2>/dev/null || true; done' 2>/dev/null || true
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 10 — Fonts
# ══════════════════════════════════════════════════════════════════════════════
step "10 — Fonts"
FONT_DST="$HOME/.local/share/fonts"
if [[ -d "$DOTFILES_DIR/.local/share/fonts" ]]; then
  if prompt_yn "Install bundled fonts and update font cache?" "y"; then
    mkdir -p "$FONT_DST"
    info "Copying bundled fonts..."
    cp -rn "$DOTFILES_DIR/.local/share/fonts/." "$FONT_DST/" 2>/dev/null || true
    fc-cache -fv "$FONT_DST" &>/dev/null || true
    log "Fonts installed and cache updated"
  else
    warn "Skipped fonts installation"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 11 — Wallpaper
# ══════════════════════════════════════════════════════════════════════════════
step "11 — Wallpaper"
if [[ -f "$DOTFILES_DIR/wallpaper.jpg" ]]; then
  if prompt_yn "Set up Catppuccin Mocha wallpaper?" "y"; then
    mkdir -p "$HOME/Pictures"
    cp -n "$DOTFILES_DIR/wallpaper.jpg" "$HOME/Pictures/catppuccin-wall-dark.jpg" 2>/dev/null || true
    log "Wallpaper → ~/Pictures/catppuccin-wall-dark.jpg"
  else
    warn "Skipped wallpaper setup"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 12 — /etc System Configs (Requires Sudo)
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "12 — /etc system configs"
  if prompt_yn "Apply system-wide configs to /etc (SDDM, sysctl performance)? (requires sudo)" "y"; then
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
    log "/etc system configs applied"
  else
    warn "Skipped /etc system configs"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 13 — Systemd User Services
# ══════════════════════════════════════════════════════════════════════════════
step "13 — Systemd user services"
if prompt_yn "Enable user systemd services (conky, mpd, syncthing, desktop daemons)?" "y"; then
  systemctl --user daemon-reload 2>/dev/null || true
  for svc in copyq greenclip i3-autoname mpd syncthing wireplumber conky desktop-music-daemon wallpaper-rotate sync-antigravity.timer; do
    if systemctl --user enable "$svc" 2>/dev/null; then
      log "Enabled: $svc"
    else
      warn "Could not enable $svc (requires graphical session; will activate on login)"
    fi
  done
else
  warn "Skipped systemd user services"
fi

# ── Carapace completions setup for fish ───────────────────────────────────────
if command -v carapace &>/dev/null && [[ -d "$HOME/.config/fish" ]]; then
  mkdir -p "$HOME/.config/fish/conf.d"
  carapace _carapace fish > "$HOME/.config/fish/conf.d/carapace.fish" 2>/dev/null || true
  cat >> "$HOME/.config/fish/conf.d/carapace.fish" << 'CARAPACE_EOF'

# ── Custom completions via carapace ──────────────────────────────────────
for __tool in instagram-cli gallery-dl spotdl instaloader aider
  complete -e "$__tool"
  complete -c "$__tool" -f -a '(_carapace_completer "'$__tool'")'
end
CARAPACE_EOF
  log "Carapace completions generated for fish"
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 14 — Default Shell → Zsh
# ══════════════════════════════════════════════════════════════════════════════
if [[ "$INSTALL_MODE" != "dotfiles" ]]; then
  step "14 — Default shell → zsh"
  ZSH_PATH="$(command -v zsh || echo '/bin/zsh')"
  if [[ "$SHELL" != "$ZSH_PATH" ]]; then
    if prompt_yn "Change login shell to zsh ($ZSH_PATH)?" "y"; then
      sudo chsh -s "$ZSH_PATH" "$WHOAMI"
      log "Default shell set to zsh (takes effect on next login)"
    else
      warn "Preserved current shell ($SHELL)"
    fi
  else
    log "zsh is already the default shell"
  fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# Step 15 — XDG User Dirs
# ══════════════════════════════════════════════════════════════════════════════
step "15 — XDG user dirs"
xdg-user-dirs-update 2>/dev/null && log "XDG user directories updated" || true

# ══════════════════════════════════════════════════════════════════════════════
# Summary / Completion Banner
# ══════════════════════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗"
echo                    "║         ✅  Installation Complete!                   ║"
echo -e                 "╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "${BOLD}  Installed & Configured Tools:${RESET}"
echo "  • Music Identifier   : shazam (CLI) & shazam -g (GUI / SongRec) [Mod+M / Mod+Shift+M]"
echo "  • Scratchpad Terminal: Super+U / Alt+U (fast i3 toggle with debouncing)"
echo "  • Workspace Autoname : autoname-workspaces (Rust dynamic icon engine)"
echo "  • Desktop Audio Loop : desktop-music-daemon + mpris-live"
echo "  • Window Helpers     : x11-grab-probe + libportal-remember-dir.so"
echo ""
echo -e "${BOLD}  Recommended Next Steps:${RESET}"
echo "  ① Reboot system       : sudo reboot"
echo "  ② GitHub CLI login    : gh auth login"
echo "  ③ Password Vault      : rbw login"
echo "  ④ Identify Song       : shazam  (plays through system speakers/headphones)"
echo ""
echo -e "${BOLD}  Documentation & Reference:${RESET}"
echo "  • TOOLS_GUIDE.md      — full keybindings & cheatsheets"
echo "  • ./install.sh --help — review script flags and modes"
echo ""
