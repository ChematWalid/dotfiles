#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/lib"
g++ -fPIC -shared -O2 -Wall -Wextra -I/usr/include/qt6 -I/usr/include/qt6/QtCore \
    "$DIR/fdm-portal-fix.cpp" \
    -lQt6Core \
    -o "$HOME/.local/lib/libfdm-portal-fix.so" -ldl
echo "Built $HOME/.local/lib/libfdm-portal-fix.so successfully"
