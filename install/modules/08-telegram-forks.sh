#!/usr/bin/env bash
# ── install/modules/08-telegram-forks.sh ──────────────────────────────────────
MODULE_ID="telegram-forks"
MODULE_NAME="Telegram Desktop Forks"
MODULE_DESC="Download and install AyuGram & 64Gram Desktop releases"
MODULE_DOTFILES_COMPAT=false

latest_release_asset() {
  local repository="$1" asset_pattern="$2" release_json
  release_json=$(mktemp)

  if ! curl --fail --silent --show-error --location \
    "https://api.github.com/repos/${repository}/releases/latest" \
    -o "$release_json"; then
    rm -f -- "$release_json"
    return 1
  fi

  jq -er --arg pattern "$asset_pattern" \
    '[.assets[] | select(.name | test($pattern; "i"))][0].browser_download_url // empty' \
    "$release_json"
  local result=$?
  rm -f -- "$release_json"
  return "$result"
}

install_64gram() {
  local install_dir="$HOME/.local/share/64Gram"
  local work_dir archive asset_url
  work_dir=$(mktemp -d)
  archive="$work_dir/64gram-linux.zip"

  if ! asset_url=$(latest_release_asset 'TDesktop-x64/tdesktop' '^64Gram_[0-9.]+_linux\.zip$'); then
    warn "Could not find the official 64Gram Linux package"
    rm -rf -- "$work_dir"
    return 1
  fi

  if ! curl --fail --silent --show-error --location "$asset_url" -o "$archive" \
    || ! unzip -tq "$archive" >/dev/null; then
    warn "Could not download or validate the 64Gram Linux package"
    rm -rf -- "$work_dir"
    return 1
  fi

  mkdir -p -- "$work_dir/extracted" "$install_dir"
  if ! unzip -oq "$archive" Telegram Updater -d "$work_dir/extracted" \
    || [[ ! -s "$work_dir/extracted/Telegram" || ! -s "$work_dir/extracted/Updater" ]]; then
    warn "64Gram archive did not contain its expected Linux executables"
    rm -rf -- "$work_dir"
    return 1
  fi

  chmod 755 "$work_dir/extracted/Telegram" "$work_dir/extracted/Updater"
  if ! install -m 755 "$work_dir/extracted/Telegram" "$install_dir/Telegram.new" \
    || ! install -m 755 "$work_dir/extracted/Updater" "$install_dir/Updater.new"; then
    warn "Could not stage the 64Gram executables"
    rm -rf -- "$work_dir"
    return 1
  fi

  mv -f -- "$install_dir/Telegram.new" "$install_dir/Telegram"
  mv -f -- "$install_dir/Updater.new" "$install_dir/Updater"
  rm -rf -- "$work_dir"
  return 0
}

run_module() {
  step "8 — Telegram Desktop Forks (AyuGram & 64Gram)"
  if ! prompt_yn "Download and configure Telegram Desktop forks (AyuGram / 64Gram)?" "y"; then
    warn "Skipped Telegram Desktop forks"
    return
  fi

  if prompt_yn "  Install AyuGram Desktop?" "y"; then
    info "Checking for an AyuGram Linux package..."
    local ayu_asset
    if [[ -x "$HOME/.local/share/AyuGram/AyuGram.bin" || -x "$HOME/.local/share/AyuGram/AyuGram" ]]; then
      log "AyuGram Desktop already present"
    elif ayu_asset=$(latest_release_asset 'AyuGram/AyuGramDesktop' '^AyuGram.*(linux|appimage|x86_64).*(\.AppImage|\.tar\.(xz|gz|zst)|\.zip)$'); then
      warn "Found an AyuGram Linux asset, but automatic extraction is not configured yet; leaving the existing installation untouched"
    else
      warn "The latest AyuGram release has no identifiable Linux binary asset; source archives are not installed as executables"
    fi
  fi

  if prompt_yn "  Install 64Gram Desktop?" "y"; then
    info "Setting up 64Gram Desktop..."
    if install_64gram; then
      log "64Gram Linux package installed; existing tdata was preserved"
    else
      warn "64Gram installation did not complete"
    fi
  fi
}
