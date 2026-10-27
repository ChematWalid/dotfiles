#!/usr/bin/env bash
# ── datetime-toggle.sh ────────────────────────────────────────────────────────
# Fast delegation to native C++ polybar-datetime --toggle
exec "${HOME}/.local/bin/polybar-datetime" --toggle
