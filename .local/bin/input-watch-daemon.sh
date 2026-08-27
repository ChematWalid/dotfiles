#!/usr/bin/env bash
# ── Persistent Input Watch Daemon ──
# Listens for hardware input events (hotplug, sleep/wake, USB reconnect)
# and instantly re-applies keyboard repeat rate (250 50) and zero-acceleration mouse raw input.

apply_settings() {
    # 1. Keyboard Layouts
    setxkbmap -layout "be,ara" -option "grp:win_space_toggle" 2>/dev/null || true
    # 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec)
    xset r rate 250 50 2>/dev/null || true
    # 3. Screen blanking
    xset s off -dpms s noblank 2>/dev/null || true
    # 4. Disable X11 core pointer acceleration
    xset m 0 0 2>/dev/null || true
    # 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
    for id in $(xinput list --id-only 2>/dev/null); do
        if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel Profile Enabled"; then
            xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1, 0 2>/dev/null || true
            xinput set-prop "$id" "libinput Accel Speed" -0.25 2>/dev/null || true
        fi
    done
}

# Apply immediately
apply_settings

# Listen for input subsystem events
udevadm monitor --subsystem-match=input --udev 2>/dev/null | while read -r line; do
    if [[ "$line" =~ "add" || "$line" =~ "bind" || "$line" =~ "change" ]]; then
        sleep 0.2
        apply_settings
    fi
done
