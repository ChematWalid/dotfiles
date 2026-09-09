#!/usr/bin/env bash
# ── install/modules/01-system-update.sh ───────────────────────────────────────
MODULE_ID="system-update"
MODULE_NAME="System Update"
MODULE_DESC="Update pacman databases and upgrade system packages (sudo pacman -Syu)"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "1 — System update"
  if prompt_yn "Run full system update (sudo pacman -Syu)?" "y"; then
    info "Updating pacman databases and upgrading packages..."
    sudo pacman -Syu --noconfirm
    log "System is up to date"
  else
    warn "Skipped system update"
  fi
}
