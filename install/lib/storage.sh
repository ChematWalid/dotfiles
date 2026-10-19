#!/usr/bin/env bash
# ── install/lib/storage.sh ───────────────────────────────────────────────────
# Storage layout configuration (Single Drive vs Multi-Drive Secondary Routing)
# ─────────────────────────────────────────────────────────────────────────────

write_storage_config() {
  local hdd_mount="$1" data_mount="$2"
  local config="$HOME/.config/dotfiles-storage.env"
  local tmp="${config}.tmp.$$"

  mkdir -p "$HOME/.config" || return 1
  (
    umask 077
    {
      printf '%s\n' '# Dotfiles storage layout'
      printf 'export HDD_MOUNT=%q\n' "$hdd_mount"
      printf 'export DATA_MOUNT=%q\n' "$data_mount"
    } > "$tmp"
  ) || { rm -f -- "$tmp"; return 1; }
  chmod 600 "$tmp" && mv -f -- "$tmp" "$config"
}

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
      write_storage_config "" ""
    fi
  elif [[ "${INSTALL_MODE:-}" == "all" ]]; then
    if [[ ! -f "$HOME/.config/dotfiles-storage.env" ]]; then
      write_storage_config "" ""
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

      if [[ "$user_hdd" != /* || "$user_data" != /* ]]; then
        warn "Storage mount paths must be absolute paths"
        return 1
      fi
      write_storage_config "$user_hdd" "$user_data"
      log "Storage configuration saved → ~/.config/dotfiles-storage.env"
    else
      write_storage_config "" ""
      log "Single-drive layout configured"
    fi
  fi

  [[ -f "$HOME/.config/dotfiles-storage.env" ]] && source "$HOME/.config/dotfiles-storage.env"
}
