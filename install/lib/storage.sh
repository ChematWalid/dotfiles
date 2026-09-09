#!/usr/bin/env bash
# ── install/lib/storage.sh ───────────────────────────────────────────────────
# Storage layout configuration (Single Drive vs Multi-Drive Secondary Routing)
# ─────────────────────────────────────────────────────────────────────────────

configure_storage() {
  mkdir -p "$HOME/.config"

  # If storage is already configured, load it unless user in custom mode wants to reconfigure
  if [[ -f "$HOME/.config/dotfiles-storage.env" ]]; then
    source "$HOME/.config/dotfiles-storage.env"
    if [[ "${INSTALL_MODE:-}" != "custom" ]]; then
      return 0
    fi
    if ! prompt_yn "Storage layout is already configured. Reconfigure storage layout?" "n"; then
      return 0
    fi
  fi

  if [[ "${INSTALL_MODE:-}" == "dotfiles" || "${INSTALL_MODE:-}" == "module" ]]; then
    if [[ ! -f "$HOME/.config/dotfiles-storage.env" ]]; then
      cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
    fi
  elif [[ "${INSTALL_MODE:-}" == "all" ]]; then
    if [[ ! -f "$HOME/.config/dotfiles-storage.env" ]]; then
      cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
      log "Default single-drive storage layout configured"
    fi
  else
    # Custom / Interactive storage configuration
    echo ""
    echo -e "${BOLD}${CYAN}══ Storage Layout Configuration ══${RESET}"
    echo "  [1] Single Drive (Default) — Store all caches, toolchains, and data on primary drive"
    echo "  [2] Multi-Drive Routing    — Route heavy caches and toolchains to a secondary drive (HDD/SSD)"
    local storage_choice=""
    read -rp "  Select storage layout [1/2, default: 1]: " storage_choice || true
    storage_choice="${storage_choice:-1}"

    if [[ "$storage_choice" == "2" ]]; then
      echo ""
      echo "Available storage mount points:"
      df -h | grep -E '^/dev/' || true
      echo ""
      local user_hdd="" user_data=""
      read -rp "  Enter secondary drive mount path (e.g. /mnt/drive2, /mnt/storage): " user_hdd || true
      read -rp "  Enter optional data drive mount path (e.g. /mnt/drive3, press Enter to use same): " user_data || true
      user_data="${user_data:-$user_hdd}"

      cat > "$HOME/.config/dotfiles-storage.env" << EOF
# Dotfiles secondary storage routing
export HDD_MOUNT="$user_hdd"
export DATA_MOUNT="$user_data"
EOF
      log "Storage configuration saved → ~/.config/dotfiles-storage.env"
    else
      cat > "$HOME/.config/dotfiles-storage.env" << 'EOF'
# Dotfiles single-drive storage layout
export HDD_MOUNT=""
export DATA_MOUNT=""
EOF
      log "Single-drive layout configured"
    fi
  fi

  [[ -f "$HOME/.config/dotfiles-storage.env" ]] && source "$HOME/.config/dotfiles-storage.env"
}
