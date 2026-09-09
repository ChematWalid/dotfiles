#!/usr/bin/env bash
# ── install/modules/03-yay-aur.sh ─────────────────────────────────────────────
MODULE_ID="yay-aur"
MODULE_NAME="yay (AUR Helper)"
MODULE_DESC="Install yay AUR helper from source (base-devel + git)"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "3 — yay (AUR helper)"
  if command -v yay &>/dev/null; then
    log "yay is already installed"
  elif prompt_yn "Install yay AUR helper?" "y"; then
    info "Installing yay prerequisites (base-devel, git)..."
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp_yay
    tmp_yay=$(mktemp -d)
    info "Cloning and building yay..."
    git clone https://aur.archlinux.org/yay.git "$tmp_yay"
    (cd "$tmp_yay" && makepkg -si --noconfirm)
    rm -rf "$tmp_yay"
    log "yay installed successfully"
  else
    warn "Skipped yay installation"
  fi
}
