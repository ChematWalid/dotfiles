#!/usr/bin/env bash
# ── wallpaper-rotate.sh ───────────────────────────────────────────────────────
# Rotate wallpapers automatically every 30 minutes.
# Delegates to native Rust wallpaper-manager daemon for 0% CPU and 0 fork overhead.
# Managed by systemd wallpaper-rotate.service.

set -euo pipefail

readonly BIN="${HOME}/.local/bin/wallpaper-manager"
if [[ -x "$BIN" ]]; then
    exec "$BIN" daemon
fi

exec wallpaper-manager daemon
