#!/usr/bin/env bash
# ── install/modules/12-etc-system.sh ──────────────────────────────────────────
MODULE_ID="etc-system"
MODULE_NAME="/etc System Configs"
MODULE_DESC="Copy system-wide configs to /etc (SDDM, sysctl performance, nosleep) [sudo]"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "12 — /etc system configs"
  if prompt_yn "Apply system-wide configs to /etc (SDDM, sysctl performance)? (requires sudo)" "y"; then
    _safe_etc() {
      local src="$1" dst="$2"
      sudo mkdir -p "$(dirname "$dst")"
      [[ -f "$dst" ]] && sudo cp "$dst" "$dst.bak" && warn "Backed up $dst"
      sudo cp "$src" "$dst"
      log "Installed /etc: $(basename "$dst")"
    }

    if [[ -f "$DOTFILES_DIR/etc/sddm.conf.d/theme.conf" ]]; then
      _safe_etc "$DOTFILES_DIR/etc/sddm.conf.d/theme.conf"             "/etc/sddm.conf.d/theme.conf"
    fi
    if [[ -f "$DOTFILES_DIR/etc/sysctl.d/99-performance.conf" ]]; then
      _safe_etc "$DOTFILES_DIR/etc/sysctl.d/99-performance.conf"       "/etc/sysctl.d/99-performance.conf"
    fi
    if [[ -f "$DOTFILES_DIR/etc/default/cpupower" ]]; then
      _safe_etc "$DOTFILES_DIR/etc/default/cpupower"                   "/etc/default/cpupower"
    fi
    if [[ -f "$DOTFILES_DIR/etc/systemd/logind.conf.d/nosleep.conf" ]]; then
      _safe_etc "$DOTFILES_DIR/etc/systemd/logind.conf.d/nosleep.conf" "/etc/systemd/logind.conf.d/nosleep.conf"
    fi

    sudo sysctl --system &>/dev/null || true
    log "/etc system configs applied"
  else
    warn "Skipped /etc system configs"
  fi
}
