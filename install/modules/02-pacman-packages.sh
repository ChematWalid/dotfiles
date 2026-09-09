#!/usr/bin/env bash
# ── install/modules/02-pacman-packages.sh ─────────────────────────────────────
MODULE_ID="pacman-packages"
MODULE_NAME="Pacman Packages"
MODULE_DESC="Install system packages from pkglist-pacman-names.txt (TeX Live, Math, SongRec, etc.)"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "2 — Pacman packages"
  if prompt_yn "Install system packages from pkglist-pacman-names.txt?" "y"; then
    local install_texlive="y"
    local install_math="y"
    local install_songrec="y"

    if [[ "${INSTALL_MODE:-}" == "custom" ]]; then
      echo -e "\n  ${BOLD}${CYAN}Granular Tool Selection:${RESET}"
      if ! prompt_yn "  Include TeX Live document suite (~3GB)?" "y"; then
        install_texlive="n"
        warn "  TeX Live excluded from package list"
      fi
      if ! prompt_yn "  Include Math & CAS applications (Cantor, LabPlot, Kig, Maxima)?" "y"; then
        install_math="n"
        warn "  Math/CAS applications excluded from package list"
      fi
      if ! prompt_yn "  Include SongRec / Shazam audio identifier?" "y"; then
        install_songrec="n"
        warn "  SongRec excluded from package list"
      fi
    fi

    info "Reading packages from pkglist-pacman-names.txt..."
    local pkgs=()
    while IFS= read -r pkg; do
      [[ -z "$pkg" || "$pkg" == \#* ]] && continue
      # Filter TeX Live if refused
      if [[ "$install_texlive" == "n" && "$pkg" == texlive* ]]; then
        continue
      fi
      # Filter Math apps if refused
      if [[ "$install_math" == "n" ]] && [[ "$pkg" =~ ^(cantor|kig|kmplot|labplot|maxima)$ ]]; then
        continue
      fi
      # Filter SongRec if refused
      if [[ "$install_songrec" == "n" && "$pkg" == "songrec" ]]; then
        continue
      fi
      pkgs+=("$pkg")
    done < "$DOTFILES_DIR/pkglist-pacman-names.txt"

    info "Installing ${#pkgs[@]} pacman packages..."
    sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null \
      || warn "Some pacman packages may not exist in repos (may be AUR) — continuing"
    log "Pacman packages installed"
  else
    warn "Skipped pacman packages installation"
  fi
}
