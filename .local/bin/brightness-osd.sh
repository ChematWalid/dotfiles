#!/usr/bin/env bash
# ── brightness-osd.sh ─────────────────────────────────────────────────────────
# Screen backlight / monitor control OSD with Dunst notification bar.
# Delegates to native Rust desktop-osd brightness for sub-millisecond execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "${SCRIPT_DIR}/desktop-osd" ]]; then
    exec "${SCRIPT_DIR}/desktop-osd" brightness "$@"
fi
if [[ -x "${HOME}/.local/bin/desktop-osd" ]]; then
    exec "${HOME}/.local/bin/desktop-osd" brightness "$@"
fi

exec desktop-osd brightness "$@"
