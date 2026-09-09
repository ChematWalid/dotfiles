#!/usr/bin/env bash
# ── install/modules/11-wallpaper.sh ───────────────────────────────────────────
MODULE_ID="wallpaper"
MODULE_NAME="Wallpaper"
MODULE_DESC="Deploy Catppuccin Mocha wallpaper to ~/Pictures"
MODULE_DOTFILES_COMPAT=true

run_module() {
  step "11 — Wallpaper"
  if [[ -f "$DOTFILES_DIR/wallpaper.jpg" ]]; then
    if prompt_yn "Set up Catppuccin Mocha wallpaper?" "y"; then
      mkdir -p "$HOME/Pictures"
      cp -n "$DOTFILES_DIR/wallpaper.jpg" "$HOME/Pictures/catppuccin-wall-dark.jpg" 2>/dev/null || true
      log "Wallpaper → ~/Pictures/catppuccin-wall-dark.jpg"
    else
      warn "Skipped wallpaper setup"
    fi
  fi
}
