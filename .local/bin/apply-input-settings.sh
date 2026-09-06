#!/usr/bin/env bash
# ── apply-input-settings.sh ───────────────────────────────────────────────────
# Applies low-latency keyboard repeat rate, dual layouts (BE/ARA), and raw 1:1 mouse input.

set -euo pipefail

apply_input() {
    # 1. Keyboard Layouts
    setxkbmap -option "" 2>/dev/null || true
    setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null || true

    # 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec)
    xset r rate 250 50 2>/dev/null || true

    # 3. Disable Screen Blanking
    xset s off -dpms s noblank 2>/dev/null || true

    # 4. Disable X11 core pointer acceleration
    xset m 0 0 2>/dev/null || true

    # 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
    for id in $(xinput list --id-only 2>/dev/null || true); do
        if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel Profile Enabled"; then
            xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1, 0 2>/dev/null || true
            xinput set-prop "$id" "libinput Accel Speed" -0.25 2>/dev/null || true
        fi
    done
}

apply_input

# Ensure background hardware hotplug watcher is active
if [[ "${1:-}" != "--no-spawn" ]]; then
    if ! pgrep -f "input-watch-daemon.sh" >/dev/null 2>&1; then
        nohup "${HOME}/.local/bin/input-watch-daemon.sh" >/dev/null 2>&1 &
    fi
fi
