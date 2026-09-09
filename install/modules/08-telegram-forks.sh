#!/usr/bin/env bash
# ── install/modules/08-telegram-forks.sh ──────────────────────────────────────
MODULE_ID="telegram-forks"
MODULE_NAME="Telegram Desktop Forks"
MODULE_DESC="Download and install AyuGram & 64Gram Desktop releases"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "8 — Telegram Desktop Forks (AyuGram & 64Gram)"
  if prompt_yn "Download and configure Telegram Desktop forks (AyuGram / 64Gram)?" "y"; then
    # AyuGram
    if prompt_yn "  Install AyuGram Desktop?" "y"; then
      info "Setting up AyuGram Desktop..."
      if [[ ! -f "$HOME/.local/share/AyuGram/AyuGram" ]]; then
        mkdir -p "$HOME/.local/share/AyuGram"
        local ayu_tar
        ayu_tar=$(mktemp)
        curl -sL "https://api.github.com/repos/AyuGram/AyuGramDesktop/releases/latest" \
          | grep "browser_download_url.*Linux.*\.tar\.xz" | cut -d : -f 2,3 | tr -d \" | tr -d ' ' | head -n 1 \
          | xargs -I{} curl -fSL "{}" -o "$ayu_tar" 2>/dev/null || true
        if [[ -f "$ayu_tar" && -s "$ayu_tar" ]]; then
          tar -xf "$ayu_tar" -C "$HOME/.local/share/AyuGram/" 2>/dev/null || true
          rm -f "$ayu_tar"
          log "AyuGram Desktop installed"
        fi
      else
        log "AyuGram Desktop already present"
      fi
    fi

    # 64Gram
    if prompt_yn "  Install 64Gram Desktop?" "y"; then
      info "Setting up 64Gram Desktop..."
      if [[ ! -f "$HOME/.local/share/64Gram/64Gram" ]]; then
        mkdir -p "$HOME/.local/share/64Gram"
        local x64_tar
        x64_tar=$(mktemp)
        curl -sL "https://api.github.com/repos/TDesktop-x64/tdesktop/releases/latest" \
          | grep "browser_download_url.*linux.*\.tar\.xz" | cut -d : -f 2,3 | tr -d \" | tr -d ' ' | head -n 1 \
          | xargs -I{} curl -fSL "{}" -o "$x64_tar" 2>/dev/null || true
        if [[ -f "$x64_tar" && -s "$x64_tar" ]]; then
          tar -xf "$x64_tar" -C "$HOME/.local/share/64Gram/" 2>/dev/null || true
          rm -f "$x64_tar"
          log "64Gram Desktop installed"
        fi
      else
        log "64Gram Desktop already present"
      fi
    fi
  else
    warn "Skipped Telegram Desktop forks"
  fi
}
