#!/usr/bin/env bash
# ── window-info.sh ────────────────────────────────────────────────────────────
# Fast delegation to native Rust i3-layout-toggle window-info
exec "${HOME}/.local/bin/i3-layout-toggle" window-info "$@"
