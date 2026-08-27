#!/usr/bin/env bash

# 1. Keyboard Layouts
setxkbmap -option ""
setxkbmap -layout "be,ara" -option "grp:win_space_toggle"

# 2. Keyboard Repeat Rate (250ms delay, 50 repeats/sec) - Must run after setxkbmap
xset r rate 250 50

# 3. Screen blanking
xset s off -dpms s noblank

# 4. Disable X11 core pointer acceleration (Strict 0/0 threshold)
xset m 0 0

# 5. Mouse Libinput Raw Input (Flat Profile: 0, 1, 0) & Speed (-0.25)
for id in $(xinput list --id-only 2>/dev/null); do
    if xinput list-props "$id" 2>/dev/null | grep -q "libinput Accel Profile Enabled"; then
        # Profile: [Adaptive, Flat, Custom] -> Set to Flat for 1:1 raw linear motion (no acceleration curve)
        xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1, 0 2>/dev/null || true
        xinput set-prop "$id" "libinput Accel Speed" -0.25 2>/dev/null || true
    fi
done

# 6. Ensure background watcher is active so settings never revert on USB/sleep/hotplug
if ! pgrep -f "input-watch-daemon.sh" > /dev/null; then
    nohup ~/.local/bin/input-watch-daemon.sh >/dev/null 2>&1 &
fi
