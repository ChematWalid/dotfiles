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

    # ── Storage Drives & Personal Symlinks (Opt-in) ──────────────────────────
    # Secondary and data drive mounts are hardware-specific and disabled by default.
    # They are only linked if explicitly configured and accepted.
    if [[ -n "${HDD_MOUNT:-}" && -d "$HDD_MOUNT" ]]; then
      if prompt_yn "Symlink secondary drive ($HDD_MOUNT) to ~/D?" "n"; then
        safe_link "$HDD_MOUNT" "$HOME/D"
      fi
    fi

    if [[ -n "${DATA_MOUNT:-}" && -d "$DATA_MOUNT" ]]; then
      if prompt_yn "Symlink data drive ($DATA_MOUNT) to ~/E and personal folders?" "n"; then
        safe_link "$DATA_MOUNT" "$HOME/E"
        [[ -d "$DATA_MOUNT/Coding" ]] && safe_link "$DATA_MOUNT/Coding" "$HOME/Coding"
        [[ -d "$DATA_MOUNT/Pictures" ]] && safe_link "$DATA_MOUNT/Pictures" "$HOME/Pictures"
        [[ -d "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" ]] && safe_link "$DATA_MOUNT/Backups/ArchLinuxData/TelegramDesktop" "$HOME/Downloads/Telegram Desktop"
      fi
    fi

    # ── ~/.config directories — symlinked wholesale ─────────────────────────────
    local config_dirs=(
      alacritty atuin bat BetterDiscord broot btop cava conky copyq
      delta direnv dunst eza fastfetch fish flameshot fselect fzf
      environment.d gh-dash gitui glow gtk-3.0 gtk-4.0 hypr i3 khal kitty lazydocker
      lazygit lf mise mpd mpv ncmpcpp nvim picom polybar qbittorrent
      qBittorrent qt5ct qt6ct rofi songrec spicetify starship superfile systemd
      tealdeer thefuck Thunar tmux tumbler xfce4 xsettingsd yazi zellij zsh zsh-plugins
      xdg-desktop-portal
    )
    for d in "${config_dirs[@]}"; do
      if [[ -d "$DOTFILES_DIR/.config/$d" ]]; then
        safe_link "$DOTFILES_DIR/.config/$d" "$HOME/.config/$d"
      fi
    done

    # Ensure systemd user service drop-in overrides (such as dunst.service.d) are supported
    if [[ -d "$HOME/.config/systemd/user" && ! -L "$HOME/.config/systemd" ]]; then
      for dropin in "$DOTFILES_DIR/.config/systemd/user"/*.d; do
        [[ -d "$dropin" ]] || continue
        safe_link "$dropin" "$HOME/.config/systemd/user/$(basename "$dropin")"
      done
    fi

    # Keep OAuth credentials in the user's private config directory, never in
    # the dotfiles checkout. Do not symlink or replace this directory.
    mkdir -p "$HOME/.config/rclone"
    chmod 700 "$HOME/.config/rclone"
    if [[ -f "$HOME/.config/rclone/rclone.conf" ]]; then
      chmod 600 "$HOME/.config/rclone/rclone.conf"
    else
      log "rclone credentials not configured; run 'rclone config' when needed"
    fi

    # Standalone .config files
    for file in chrome-flags.conf rofi-rbw.rc starship.toml; do
      if [[ -f "$DOTFILES_DIR/.config/$file" ]]; then
        safe_link "$DOTFILES_DIR/.config/$file" "$HOME/.config/$file"
      fi
    done

    # ── ~/.config/autostart desktop overrides ──────────────────────────────────
    mkdir -p "$HOME/.config/autostart"
    for desktop in "$DOTFILES_DIR/.config/autostart"/*.desktop; do
      [[ -f "$desktop" ]] || continue
      safe_link "$desktop" "$HOME/.config/autostart/$(basename "$desktop")"
    done

    # ── ~/.local/bin scripts ────────────────────────────────────────────────────
    mkdir -p "$HOME/.local/bin"
    local native_bin
    local -a native_bins=(desktop-music-daemon autoname-workspaces rofi-clipboard mpris-live x11-grab-probe)
    for script in "$DOTFILES_DIR/.local/bin"/*; do
      [[ -f "$script" || -L "$script" ]] || continue
      native_bin="$(basename "$script")"
      if [[ " ${native_bins[*]} " == *" $native_bin "* ]]; then
        continue
      fi
      chmod +x "$script" 2>/dev/null || true
      safe_link "$script" "$HOME/.local/bin/$native_bin"
    done

    # ── ~/.local/src source directories ─────────────────────────────────────────
    if [[ -d "$DOTFILES_DIR/.local/src" ]]; then
      mkdir -p "$HOME/.local/src"
      local source_root="$DOTFILES_DIR/.local/src"
      local source_copy_failed=false
      if ! (
        cd "$source_root" &&
          find . \
            \( -type d -name target -prune \) -o \
            \( \( -type f -o -type l \) \
              -exec cp -an --parents -t "$HOME/.local/src" {} + \)
      ); then
        source_copy_failed=true
      fi
      if [[ "$source_copy_failed" == true ]]; then
        warn "Some local source files could not be copied"
      fi
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
      if "$DOTFILES_DIR/.local/bin/sync-cheats"; then
        log "Tealdeer and Navi custom cheatsheets synchronized"
      else
        warn "Tealdeer and Navi cheatsheet synchronization failed; review the output above"
      fi
    fi

    # ── Custom Zsh completions ─────────────────────────────────────────────────
    if [[ -d "$DOTFILES_DIR/.zsh/completions" ]]; then
      mkdir -p "$HOME/.zsh/completions"
      if cp -rn "$DOTFILES_DIR/.zsh/completions/." "$HOME/.zsh/completions/"; then
        log "Custom Zsh completions installed"
      else
        warn "Some custom Zsh completions could not be copied"
      fi
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
      if ! update-desktop-database "$HOME/.local/share/applications"; then
        warn "Could not refresh the desktop application database"
      fi
    fi
    log "All dotfiles symlinked"
  else
    warn "Skipped dotfiles symlinking"
  fi
}
