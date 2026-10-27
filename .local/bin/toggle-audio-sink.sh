#!/usr/bin/env bash
# ── toggle-audio-sink.sh ──────────────────────────────────────────────────────
# Fast, robust audio output toggler between sinks with instant Dunst OSD feedback.
# Delegates to native Rust desktop-osd sink for sub-millisecond execution.

set -euo pipefail

cmd_args=("$@")
if [[ ${#cmd_args[@]} -eq 0 ]]; then
    cmd_args=("toggle")
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -x "${SCRIPT_DIR}/desktop-osd" ]]; then
    exec "${SCRIPT_DIR}/desktop-osd" sink "${cmd_args[@]}"
fi
if [[ -x "${HOME}/.local/bin/desktop-osd" ]]; then
    exec "${HOME}/.local/bin/desktop-osd" sink "${cmd_args[@]}"
fi

exec desktop-osd sink "${cmd_args[@]}"
