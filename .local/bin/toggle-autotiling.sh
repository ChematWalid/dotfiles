#!/usr/bin/env bash
# ── toggle-autotiling.sh ──────────────────────────────────────────────────────
# Fast delegation to native Rust i3-layout-toggle autotiling-toggle
exec "${HOME}/.local/bin/i3-layout-toggle" autotiling-toggle "$@"
