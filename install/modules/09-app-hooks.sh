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
    if git config --global include.path "$HOME/.config/delta/catppuccin.gitconfig"; then
      log "Git Delta Catppuccin theme registered"
    else
      warn "Could not register the Git Delta theme"
    fi
  fi

  # Thunar Location Entry
  if command -v xfconf-query &>/dev/null; then
    if xfconf-query -c thunar -p /last-location-bar -s "ThunarLocationEntry" --create -t string; then
      log "Thunar location entry enabled"
    else
      warn "Could not enable Thunar's editable location entry"
    fi
  fi

  # Bat theme cache
  if command -v bat &>/dev/null; then
    if bat cache --build; then
      log "Bat cache built with Catppuccin Mocha"
    else
      warn "Could not build the Bat syntax theme cache"
    fi
  fi

  # TeX Live formats
  if command -v fmtutil-user &>/dev/null; then
    if fmtutil-user --all; then
      log "TeX Live formats generated"
    else
      warn "TeX Live format generation failed"
    fi
  fi

  # Secondary drive cache routing (strictly opt-in, disabled by default)
  if [[ -f "$HOME/.config/dotfiles-storage.env" ]]; then
    source "$HOME/.config/dotfiles-storage.env"
  fi

  local active_hdd="${HDD_MOUNT:-}"
  local hdd_routed=false
  if [[ -n "$active_hdd" && -d "$active_hdd" ]] && command -v hdd-route &>/dev/null; then
    if prompt_yn "Apply secondary drive cache routing (hdd-route) to $active_hdd?" "n"; then
      info "Applying secondary drive routing for developer caches and toolchains..."
      if hdd-route all; then
        log "Secondary drive routing configured"
        hdd_routed=true
      else
        warn "Secondary drive routing failed; review the hdd-route output"
      fi
    else
      warn "Skipped secondary drive cache routing (using single-drive primary storage)"
    fi
  fi

  # Polyglot runtime restoration via mise
  if command -v mise &>/dev/null; then
    if prompt_yn "Restore polyglot toolchains via mise?" "y"; then
      info "Restoring polyglot runtimes via mise..."
      if [[ "$hdd_routed" == true && -n "$active_hdd" && -d "$active_hdd" ]]; then
        export MISE_DATA_DIR="$active_hdd/.mise"
        export MISE_CACHE_DIR="$active_hdd/.cache/mise"
      fi
      if mise install -y; then
        log "Mise polyglot toolchains restored"
      else
        warn "Mise could not install all configured toolchains"
      fi
    fi
  fi

  # Pre-compile zsh completion dumps to bytecode
  if command -v zsh &>/dev/null; then
    zsh -c 'for f in ~/.zcompdump*; do zcompile "$f" 2>/dev/null || true; done' 2>/dev/null || true
  fi
}
