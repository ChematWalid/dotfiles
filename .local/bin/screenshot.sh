#!/usr/bin/env bash
# ── screenshot.sh ─────────────────────────────────────────────────────────────
# Wrapper delegating to flameshot-safe.sh.

set -euo pipefail
exec "${HOME}/.local/bin/flameshot-safe.sh" "$@"
