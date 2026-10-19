#!/usr/bin/env bash
set -euo pipefail

# Stop graphical-session services while the X session is still available.
systemctl --user stop i3-session.target || true
exec i3-msg exit
