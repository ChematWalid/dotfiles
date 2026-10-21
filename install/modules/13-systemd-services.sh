#!/usr/bin/env bash
# ── install/modules/13-systemd-services.sh ────────────────────────────────────
MODULE_ID="systemd-services"
MODULE_NAME="Systemd User Services"
MODULE_DESC="Enable selected user systemd services"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "13 — Systemd user services"
  if prompt_yn "Enable selected user systemd services?" "y"; then
    if ! systemctl --user daemon-reload; then
      warn "Could not reload user systemd units; review the systemctl output before enabling services"
      return 0
    fi
    local svc
    systemctl --user disable --now sync-antigravity.timer sync-antigravity.path sync-antigravity.service 2>/dev/null || true
    # CopyQ needs the live i3 DISPLAY/XAUTHORITY environment and is started by
    # the i3 autostart hook after importing those credentials.
    systemctl --user disable copyq.service 2>/dev/null || true
    # Core desktop daemons
    for svc in i3-autoname desktop-music-daemon wireplumber; do
      if systemctl --user enable "$svc" 2>/dev/null; then
        log "Enabled core desktop service: $svc"
      else
        warn "Could not enable $svc; review the systemctl output above"
      fi
    done

    # Optional background app services (only enable if installed/available)
    for svc in rustdesk mpd syncthing muslimtify; do
      if systemctl --user list-unit-files "${svc}.service" &>/dev/null || [[ -f "$HOME/.config/systemd/user/${svc}.service" || -f "/usr/lib/systemd/user/${svc}.service" ]]; then
        if [[ "${INSTALL_MODE:-}" == "custom" ]]; then
          if ! prompt_yn "  Enable optional service ${svc}?" "n"; then
            continue
          fi
        fi
        if systemctl --user enable "$svc" 2>/dev/null; then
          log "Enabled app service: $svc"
        fi
      fi
    done
  else
    warn "Skipped systemd user services"
  fi
}
