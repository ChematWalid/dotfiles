#!/usr/bin/env bash
set -euo pipefail

# The user manager and D-Bus can outlive i3 and retain stale X11 credentials.
# Refresh systemd's display credentials and D-Bus's display/Qt environment
# before starting graphical services or allowing GUI services to auto-activate.
systemctl --user import-environment DISPLAY XAUTHORITY I3SOCK
LC_ALL=en_US.UTF-8 QT_QPA_PLATFORMTHEME=qt6ct \
    dbus-update-activation-environment DISPLAY XAUTHORITY LC_ALL QT_QPA_PLATFORMTHEME
systemctl --user start i3-session.target

# .xprofile may still be applying input settings in the background while i3
# starts. Reapply them now that the i3 display environment is ready so the
# keyboard repeat rate does not fall back to the X server default.
"${HOME}/.local/bin/apply-input-settings.sh"

# Make the display compositor and tray host available before tray clients.
systemctl --user start picom.service || true
systemctl --user restart polybar.service || true

# Start the rest after the X11 display and Polybar tray are initialized.
systemctl --user start \
    copyq.service \
    conky.service \
    wallpaper-rotate.service \
    autotiling.service \
    input-watch.service \
    i3-autoname.service || true
