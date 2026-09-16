#!/usr/bin/env bash
# ── launch.sh ─────────────────────────────────────────────────────────────────
# Clean, reliable Polybar restart launcher with IPC initialization guard.

set -euo pipefail

# Terminate existing Polybar and child module instances gracefully
killall polybar 2>/dev/null || true
pkill -x "mpris-live" 2>/dev/null || true
pkill -f "datetime-tail.sh" 2>/dev/null || true
pkill -f "network-tail.sh" 2>/dev/null || true

# Wait until all polybar processes have shut down (max 1s)
for _ in {1..10}; do
    if ! pgrep -u "${UID:-$(id -u)}" -x polybar >/dev/null; then
        break
    fi
    sleep 0.1
done

# Force kill any lingering processes if still alive
killall -9 polybar 2>/dev/null || true

# Launch main polybar
DISPLAY="${DISPLAY:-:0}" setsid polybar main -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar.log 2>&1 &

# Launch tray popup bar
DISPLAY="${DISPLAY:-:0}" setsid polybar tray -c "${HOME}/.config/polybar/config.ini" > /tmp/polybar-tray.log 2>&1 &

# Wait for IPC socket to initialize and hide Polybar by default if requested
if [[ "${1:-}" != "--show" ]]; then
    for _ in {1..20}; do
        MAIN_PID=$(pgrep -f "polybar main" | head -1 || true)
        if [[ -n "$MAIN_PID" ]] && polybar-msg -p "$MAIN_PID" cmd hide 2>/dev/null; then
            break
        fi
        sleep 0.05
    done
fi

# Always hide tray popup bar by default on launch
for _ in {1..20}; do
    TRAY_PID=$(pgrep -f "polybar tray" | head -1 || true)
    if [[ -n "$TRAY_PID" ]] && polybar-msg -p "$TRAY_PID" cmd hide 2>/dev/null; then
        break
    fi
    sleep 0.05
done
