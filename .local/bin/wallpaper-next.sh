#!/usr/bin/env bash
# ── wallpaper-next.sh ─────────────────────────────────────────────────────────
# Pick a new random wallpaper immediately and reset rotation timer.
# Delegates to native Rust wallpaper-manager next for instant switching.

set -euo pipefail

readonly BIN="${HOME}/.local/bin/wallpaper-manager"
if [[ -x "$BIN" ]]; then
    exec "$BIN" next
fi

exec wallpaper-manager next
