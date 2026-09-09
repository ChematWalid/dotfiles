#!/usr/bin/env bash
# ── install/modules/13-systemd-services.sh ────────────────────────────────────
MODULE_ID="systemd-services"
MODULE_NAME="Systemd User Services"
MODULE_DESC="Enable user systemd services (conky, mpd, syncthing, desktop daemons) & carapace"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "13 — Systemd user services"
  if prompt_yn "Enable user systemd services (conky, mpd, syncthing, desktop daemons)?" "y"; then
    systemctl --user daemon-reload 2>/dev/null || true
    local svc
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
}
