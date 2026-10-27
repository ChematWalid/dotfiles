#!/usr/bin/env bash
# ── toggle-scratchpad.sh ──────────────────────────────────────────────────────
# Fast delegation to native Rust i3-layout-toggle scratchpad
exec "${HOME}/.local/bin/i3-layout-toggle" scratchpad "$@"
