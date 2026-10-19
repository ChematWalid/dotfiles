#!/usr/bin/env bash
# ── smart-open.sh ─────────────────────────────────────────────────────────────
# Opens an application in the current workspace:
# - If an instance of the window already exists in i3, moves it to the
#   CURRENT workspace and focuses it (and pings the binary if withdrawn to tray).
# - Otherwise, launches the command freshly on the current workspace.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <class_regex> <command> [args...]" >&2
    exit 1
fi

readonly CLASS_REGEX="$1"
shift

# Let i3 match, move, and focus in one IPC request. A missing match returns
# nonzero, so no full-tree query or jq process is needed before launching.
if i3-msg "[class=\"(?i)${CLASS_REGEX}\"] move workspace current, focus" >/dev/null 2>&1; then
    # Ping the command in the background so if the window was minimized/withdrawn to tray, it un-hides
    nohup "$@" >/dev/null 2>&1 &
else
    exec "$@"
fi
