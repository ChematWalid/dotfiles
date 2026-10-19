#!/usr/bin/env bash
# ── install/modules/13-systemd-services.sh ────────────────────────────────────
MODULE_ID="systemd-services"
MODULE_NAME="Systemd User Services"
MODULE_DESC="Enable selected user systemd services"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "13 — Systemd user services"
  if prompt_yn "Enable selected user systemd services?" "y"; then
    systemctl --user daemon-reload 2>/dev/null || true
    local svc
    systemctl --user disable --now sync-antigravity.timer 2>/dev/null || true
    # CopyQ needs the live i3 DISPLAY/XAUTHORITY environment and is started by
    # the i3 autostart hook after importing those credentials.
    systemctl --user disable copyq.service 2>/dev/null || true
    for svc in greenclip i3-autoname mpd syncthing wireplumber desktop-music-daemon muslimtify sync-antigravity.service sync-antigravity.path; do
      if systemctl --user enable "$svc" 2>/dev/null; then
        log "Enabled: $svc"
      else
        warn "Could not enable $svc (requires graphical session; will activate on login)"
      fi
    done
  else
    warn "Skipped systemd user services"
  fi
}
