#!/usr/bin/env bash
# ── install/modules/14-default-shell.sh ────────────────────────────────────
MODULE_ID="default-shell"
MODULE_NAME="Default Shell (Zsh)"
MODULE_DESC="Set zsh as the default user login shell (chsh -s)"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "14 — Default shell → zsh"
  local zsh_path
  zsh_path="$(command -v zsh || echo '/bin/zsh')"
  if [[ "$SHELL" != "$zsh_path" ]]; then
    if prompt_yn "Change login shell to zsh ($zsh_path)?" "y"; then
      sudo chsh -s "$zsh_path" "$WHOAMI"
      log "Default shell set to zsh (takes effect on next login)"
    else
      warn "Preserved current shell ($SHELL)"
    fi
  else
    log "zsh is already the default shell"
  fi

  # Step 15: XDG user dirs update
  step "15 — XDG user dirs"
  if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    if xdg-user-dirs-update; then
      log "XDG user directories updated"
    else
      warn "Could not update XDG user directories"
    fi
  fi
}
