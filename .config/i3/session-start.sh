#!/usr/bin/env bash
set -euo pipefail

# The user manager can outlive i3 and keep stale X11 credentials. Import the
# active session values before starting any graphical user services.
systemctl --user import-environment DISPLAY XAUTHORITY

# Make the display compositor and tray host available before tray clients.
systemctl --user start picom.service
"${HOME}/.config/polybar/launch.sh" --show

# Start the rest after the X11 display and Polybar tray are initialized.
systemctl --user start \
    copyq.service \
    conky.service \
    wallpaper-rotate.service \
    autotiling.service \
    input-watch.service \
    i3-autoname.service
