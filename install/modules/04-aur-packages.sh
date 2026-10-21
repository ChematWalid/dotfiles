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
      local install_vpn="y"
      local install_heavy="y"
      if [[ "${INSTALL_MODE:-}" == "custom" ]]; then
        echo -e "\n  ${BOLD}${CYAN}Granular AUR Tool Selection:${RESET}"
        if ! prompt_yn "  Include VPN clients (ivpn, ivpn-ui)?" "y"; then
          install_vpn="n"
          warn "  VPN clients excluded"
        fi
        if ! prompt_yn "  Include heavy/proprietary desktop apps (spotify, postman-bin, projectlibre)?" "y"; then
          install_heavy="n"
          warn "  Heavy desktop apps excluded"
        fi
      fi

      info "Installing AUR packages..."
      local aur_pkgs=()
      while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue
        [[ "$pkg" == *-debug ]] && continue
        if [[ "$install_vpn" == "n" ]] && [[ "$pkg" =~ ^(ivpn|ivpn-ui)$ ]]; then
          continue
        fi
        if [[ "$install_heavy" == "n" ]] && [[ "$pkg" =~ ^(spotify|postman-bin|projectlibre)$ ]]; then
          continue
        fi
        aur_pkgs+=("$pkg")
      done < "$DOTFILES_DIR/pkglist-aur-names.txt"

      if yay -S --needed --noconfirm "${aur_pkgs[@]}"; then
        log "AUR packages installed"
      else
        warn "AUR package installation failed; review the yay output and rerun this module after resolving the error"
      fi
    else
      warn "Skipped AUR packages installation"
    fi
  else
    warn "yay not present — skipping AUR packages"
  fi
}
