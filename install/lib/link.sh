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
    local backup="$dst.bak"
    local suffix=1
    while [[ -e "$backup" || -L "$backup" ]]; do
      backup="$dst.bak.$suffix"
      ((suffix += 1))
    done
    warn "Backing up: $dst → $backup"
    mv -- "$dst" "$backup"
  fi
  [[ -L "$dst" ]] && rm -f "$dst"
  ln -s "$src" "$dst"
}
