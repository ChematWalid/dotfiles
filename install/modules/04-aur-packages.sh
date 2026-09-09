#!/usr/bin/env bash
# ── install/modules/04-aur-packages.sh ────────────────────────────────────────
MODULE_ID="aur-packages"
MODULE_NAME="AUR Packages"
MODULE_DESC="Install AUR packages from pkglist-aur-names.txt using yay"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "4 — AUR packages"
  if command -v yay &>/dev/null; then
    if prompt_yn "Install AUR packages from pkglist-aur-names.txt?" "y"; then
      info "Installing AUR packages..."
      local aur_pkgs=()
      while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        [[ "$pkg" == *-debug ]] && continue
        aur_pkgs+=("$pkg")
      done < "$DOTFILES_DIR/pkglist-aur-names.txt"

      yay -S --needed --noconfirm "${aur_pkgs[@]}" 2>/dev/null \
        || warn "Some AUR packages failed — check manually if needed"
      log "AUR packages done"
    else
      warn "Skipped AUR packages installation"
    fi
  else
    warn "yay not present — skipping AUR packages"
  fi
}
