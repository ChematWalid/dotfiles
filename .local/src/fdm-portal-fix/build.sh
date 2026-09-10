#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/lib"
g++ -fPIC -shared -O2 -I/usr/include/qt6 -I/usr/include/qt6/QtCore \
    "$DIR/fdm-portal-fix.cpp" \
    /mnt/drive2/.local/share/freedownloadmanager/lib/libQt6Core.so.6 \
    -o "$HOME/.local/lib/libfdm-portal-fix.so" -ldl
echo "Built $HOME/.local/lib/libfdm-portal-fix.so successfully"
