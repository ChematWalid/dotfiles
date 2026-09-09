#!/usr/bin/env bash
# ── install/modules/09-app-hooks.sh ───────────────────────────────────────────
MODULE_ID="app-hooks"
MODULE_NAME="App Configurations & Hooks"
MODULE_DESC="BetterDiscord injection, Git Delta theme, Thunar, Bat cache, Mise toolchains"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "9 — App Configurations & Catppuccin Mocha Hooks"

  # BetterDiscord injection into Discord
  local discord_core
  discord_core=$(find "$HOME/.config/discord" -name "discord_desktop_core" -type d 2>/dev/null | head -1 || true)
  if [[ -n "$discord_core" && -f "$discord_core/index.js" ]]; then
    if prompt_yn "Inject BetterDiscord into Discord core?" "y"; then
      if ! grep -q "betterdiscord.asar" "$discord_core/index.js"; then
        echo "require('$HOME/.config/BetterDiscord/data/betterdiscord.asar');" | cat - "$discord_core/index.js" > "$discord_core/index.js.tmp" && mv "$discord_core/index.js.tmp" "$discord_core/index.js"
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

  local active_hdd="${HDD_MOUNT:-/mnt/drive2}"
  if [[ -n "$active_hdd" && -d "$active_hdd" ]] && command -v hdd-route &>/dev/null; then
    info "Applying secondary drive routing for developer caches and toolchains..."
    hdd-route all 2>/dev/null || true
    log "Secondary drive routing configured"
  fi

  # Polyglot runtime restoration via mise
  if command -v mise &>/dev/null; then
    if prompt_yn "Restore polyglot toolchains via mise?" "y"; then
      info "Restoring polyglot runtimes via mise..."
      export MISE_DATA_DIR="${active_hdd:-$HOME}/.mise"
      export MISE_CACHE_DIR="${active_hdd:-$HOME}/.cache/mise"
      mise install -y 2>/dev/null || true
      log "Mise polyglot toolchains restored"
    fi
  fi

  # Pre-compile zsh completion dumps to bytecode
  if command -v zsh &>/dev/null; then
    zsh -c 'for f in ~/.zcompdump*; do zcompile "$f" 2>/dev/null || true; done' 2>/dev/null || true
  fi
}
