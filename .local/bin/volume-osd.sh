#!/usr/bin/env bash
# ── volume-osd.sh ─────────────────────────────────────────────────────────────
# High-performance volume control OSD with Dunst notification bar and rate limiting.
# Delegates to native Rust desktop-osd volume for sub-millisecond execution.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "${SCRIPT_DIR}/desktop-osd" ]]; then
    exec "${SCRIPT_DIR}/desktop-osd" volume "$@"
fi
if [[ -x "${HOME}/.local/bin/desktop-osd" ]]; then
    exec "${HOME}/.local/bin/desktop-osd" volume "$@"
fi

exec desktop-osd volume "$@"
