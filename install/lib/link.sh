#!/usr/bin/env bash
# ── install/lib/link.sh ───────────────────────────────────────────────────────
# Safe symlinking and backup engine
# ─────────────────────────────────────────────────────────────────────────────

safe_link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "Backing up: $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  [[ -L "$dst" ]] && rm -f "$dst"
  ln -s "$src" "$dst"
}
