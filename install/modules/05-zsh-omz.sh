#!/usr/bin/env bash
# ── install/modules/05-zsh-omz.sh ─────────────────────────────────────────────
MODULE_ID="zsh-omz"
MODULE_NAME="Oh-My-Zsh & Plugins"
MODULE_DESC="Install Oh-My-Zsh and plugins (autosuggestions, syntax-highlighting, catppuccin)"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "5 — Oh-My-Zsh + plugins"
  if prompt_yn "Install Oh-My-Zsh and custom zsh plugins?" "y"; then
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
      info "Installing Oh-My-Zsh..."
      local installer_script
      if ! installer_script=$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh); then
        warn "Could not download the Oh-My-Zsh installer"
        return 0
      fi
      if ! RUNZSH=no CHSH=no sh -c "$installer_script"; then
        warn "Oh-My-Zsh installation failed; review the installer output"
        return 0
      fi
      log "Oh-My-Zsh installed"
    else
      log "Oh-My-Zsh is already present"
    fi

    local omz_custom="$HOME/.oh-my-zsh/custom"

    _install_omz_plugin() {
      local name="$1" url="$2"
      local dest="$omz_custom/plugins/$name"
      if [[ ! -d "$dest" ]]; then
        info "Cloning zsh plugin: $name"
        git clone --depth=1 "$url" "$dest"
      else
        info "Updating zsh plugin: $name"
        if ! git -C "$dest" pull --ff-only; then
          warn "Could not update $name; keeping the installed version"
        fi
      fi
    }

    _install_omz_plugin "zsh-autosuggestions"      "https://github.com/zsh-users/zsh-autosuggestions"
    _install_omz_plugin "zsh-syntax-highlighting"  "https://github.com/zsh-users/zsh-syntax-highlighting"
    _install_omz_plugin "zsh-completions"          "https://github.com/zsh-users/zsh-completions"
    _install_omz_plugin "fast-syntax-highlighting" "https://github.com/zdharma-continuum/fast-syntax-highlighting"
    _install_omz_plugin "fzf-tab"                  "https://github.com/Aloxaf/fzf-tab"

    mkdir -p "$omz_custom/plugins/catppuccin-syntax-highlighting"
    if [[ -f "$DOTFILES_DIR/.config/zsh-plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]]; then
      cp "$DOTFILES_DIR/.config/zsh-plugins/catppuccin_mocha-zsh-syntax-highlighting.zsh" \
         "$omz_custom/plugins/catppuccin-syntax-highlighting/"
    fi
    log "Zsh plugins configured"
  else
    warn "Skipped Oh-My-Zsh and plugins"
  fi
}
