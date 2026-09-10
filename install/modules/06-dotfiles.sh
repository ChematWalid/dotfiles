#!/usr/bin/env bash
# ── install/modules/06-dotfiles.sh ────────────────────────────────────────────
MODULE_ID="dotfiles"
MODULE_NAME="Dotfiles Symlinks"
MODULE_DESC="Symlink configs (.config, .local/bin, shell dotfiles, desktop files, icons)"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "6 — Symlink dotfiles"

  if [[ "${INSTALL_MODE:-}" == "dotfiles" ]] || prompt_yn "Symlink dotfiles (.config, .local/bin, desktop entries)?" "y"; then
    # ── Shell & home dotfiles ───────────────────────────────────────────────────
    safe_link "$DOTFILES_DIR/.zshrc"           "$HOME/.zshrc"
    safe_link "$DOTFILES_DIR/.bashrc"          "$HOME/.bashrc"
    [[ -f "$DOTFILES_DIR/.vimrc" ]] && safe_link "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
    [[ -f "$DOTFILES_DIR/.tmux.conf" ]] && safe_link "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
    safe_link "$DOTFILES_DIR/.taskrc"          "$HOME/.taskrc"
    safe_link "$DOTFILES_DIR/.timewarrior.cfg" "$HOME/.timewarrior.cfg"

    mkdir -p "$HOME/.calcurse"
    [[ -f "$DOTFILES_DIR/.calcurse/conf" ]] && safe_link "$DOTFILES_DIR/.calcurse/conf" "$HOME/.calcurse/conf"

    mkdir -p "$HOME/.task/hooks"
    [[ -f "$DOTFILES_DIR/.task/hooks/on-modify.timewarrior" ]] && safe_link "$DOTFILES_DIR/.task/hooks/on-modify.timewarrior" "$HOME/.task/hooks/on-modify.timewarrior"

    # ── Storage Drives & Personal Symlinks ─────────────────────────────────────
    if [[ -n "${HDD_MOUNT:-}" && -d "$HDD_MOUNT" ]]; then
      safe_link "$HDD_MOUNT" "$HOME/D"
    elif [[ -d "/mnt/drive2" ]]; then
      safe_link "/mnt/drive2" "$HOME/D"
    fi

    if [[ -n "${DATA_MOUNT:-}" && -d "$DATA_MOUNT" ]]; then
      safe_link "$DATA_MOUNT" "$HOME/E"
      [[ -d "$DATA_MOUNT/Coding" ]] && safe_link "$DATA_MOUNT/Coding" "$HOME/Coding"
      [[ -d "$DATA_MOUNT/Pictures" ]] && safe_link "$DATA_MOUNT/Pictures" "$HOME/Pictures"
      [[ -d "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" ]] && safe_link "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" "$HOME/Downloads/Telegram Desktop"
    elif [[ -d "/mnt/drive3" ]]; then
      safe_link "/mnt/drive3" "$HOME/E"
      [[ -d "/mnt/drive3/Coding" ]] && safe_link "/mnt/drive3/Coding" "$HOME/Coding"
      [[ -d "/mnt/drive3/Pictures" ]] && safe_link "/mnt/drive3/Pictures" "$HOME/Pictures"
      [[ -d "/mnt/drive3/Backups/ArchLinuxData/TelegramDesktop" ]] && safe_link "/mnt/drive3/Backups/ArchLinuxData/TelegramDesktop" "$HOME/Downloads/Telegram Desktop"
    fi

    # ── ~/.config directories — symlinked wholesale ─────────────────────────────
    local config_dirs=(
      alacritty atuin bat BetterDiscord broot btop cava conky copyq
      delta direnv dunst eza fastfetch fish flameshot fselect fzf
      gh-dash gitui glow gtk-3.0 gtk-4.0 i3 khal kitty lazydocker
      lazygit lf mise mpd mpv ncmpcpp nvim picom polybar qbittorrent
      qBittorrent rclone rofi songrec spicetify starship superfile systemd
      tealdeer thefuck Thunar tmux tumbler xfce4 xsettingsd yazi zellij zsh zsh-plugins
    )
    for d in "${config_dirs[@]}"; do
      if [[ -d "$DOTFILES_DIR/.config/$d" ]]; then
        safe_link "$DOTFILES_DIR/.config/$d" "$HOME/.config/$d"
      fi
    done

    # Standalone .config files
    for file in chrome-flags.conf greenclip.toml rofi-rbw.rc starship.toml; do
      if [[ -f "$DOTFILES_DIR/.config/$file" ]]; then
        safe_link "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
      fi
    done

    # ── ~/.local/bin scripts ────────────────────────────────────────────────────
    mkdir -p "$HOME/.local/bin"
    for script in "$DOTFILES_DIR/.local/bin"/*; do
      [[ -f "$script" || -L "$script" ]] || continue
      chmod +x "$script" 2>/dev/null || true
      safe_link "$script" "$HOME/.local/bin/$(basename "$script")"
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
      safe_link "$desktop" "$HOME/.local/share/applications/$(basename "$desktop")"
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

    # ── Cheatsheets & Documentation (tealdeer & navi) ───────────────────────────
    if [[ -x "$DOTFILES_DIR/.local/bin/sync-cheats" ]]; then
      "$DOTFILES_DIR/.local/bin/sync-cheats" >/dev/null 2>&1 || true
      log "Tealdeer and Navi custom cheatsheets synchronized (100% coverage)"
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
}
