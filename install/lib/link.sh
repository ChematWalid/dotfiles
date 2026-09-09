#!/usr/bin/env bash
# ── install/lib/link.sh ───────────────────────────────────────────────────────
# Safe symlinking and backup engine
# ─────────────────────────────────────────────────────────────────────────────

safe_link() {
  local src="$1" dst="$2"
  # If destination is already a symlink pointing directly to source, skip to avoid breaking active sockets
  if [[ -L "$dst" ]] && [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "Backing up: $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  [[ -L "$dst" ]] && rm -f "$dst"
  ln -s "$src" "$dst"
}
