#!/usr/bin/env bash
# ── install/modules/10-fonts.sh ───────────────────────────────────────────────
MODULE_ID="fonts"
MODULE_NAME="Fonts"
MODULE_DESC="Install bundled fonts to ~/.local/share/fonts and update font cache"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "10 — Fonts"
  local font_dst="$HOME/.local/share/fonts"
  if [[ -d "$DOTFILES_DIR/.local/share/fonts" ]]; then
    if prompt_yn "Install bundled fonts and update font cache?" "y"; then
      mkdir -p "$font_dst"
      info "Copying bundled fonts..."
      cp -rn "$DOTFILES_DIR/.local/share/fonts/." "$font_dst/" 2>/dev/null || true
      fc-cache -fv "$font_dst" &>/dev/null || true
      log "Fonts installed and cache updated"
    else
      warn "Skipped fonts installation"
    fi
  fi
}
