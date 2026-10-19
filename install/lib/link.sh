#!/usr/bin/env bash
# ── install/lib/link.sh ───────────────────────────────────────────────────────
# Safe symlinking and backup engine
# ─────────────────────────────────────────────────────────────────────────────

safe_link() {
  local src="$1" dst="$2"
  # Most installed links use the exact source path as their target. Compare it
  # directly first so the common case needs only one readlink process.
  if [[ -L "$dst" ]]; then
    local existing_target
    existing_target="$(readlink -- "$dst" 2>/dev/null)" || existing_target=""
    if [[ "$existing_target" == "$src" ]]; then
      return 0
    fi
    # Preserve canonical-path equality for links created through aliases.
    if [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
      return 0
    fi
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
