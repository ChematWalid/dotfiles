#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="/home/walid/E/Study/3- University/M1 - RSD"
DEST_REMOTE="gdrive:University/Master - Reseau et Systemes Distribués"
LOG_DIR="$HOME/.local/state"
LOG_FILE="$LOG_DIR/sync-m1-rsd.log"
LOCK_FILE="/tmp/sync-m1-rsd-watcher.lock"
DEBOUNCE_SECONDS=8

mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Ensure single instance
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    log "Watcher already running. Exiting."
    exit 0
fi

# Cleanup on exit
cleanup() {
    log "Stopping watcher service..."
    trap - SIGTERM SIGINT EXIT
    kill $(jobs -p) 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT EXIT

if [[ ! -d "$SOURCE_DIR" ]]; then
    log "ERROR: Source directory '$SOURCE_DIR' does not exist."
    exit 1
fi

do_sync() {
    log "Starting rclone sync (local -> gdrive)..."
    rclone sync "$SOURCE_DIR" "$DEST_REMOTE" \
        --create-empty-src-dirs \
        --transfers 4 \
        --checkers 8 \
        --fast-list \
        --exclude ".git/**" \
        --exclude "*.tmp" \
        --exclude "*~" \
        --exclude ".*.swp" \
        --exclude ".~lock.*" \
        --exclude ".goutputstream-*" \
        --exclude ".DS_Store" \
        --log-file="$LOG_FILE" \
        --log-level NOTICE || {
            log "WARNING: rclone sync exited with error status $?"
            return 0
        }
    log "Sync completed successfully."
}

# 1. Initial sync on startup to guarantee consistency
log "=== M1 - RSD File Watcher Started ==="
do_sync

# Regex to ignore temp and editor swap files in inotify events
EXCLUDE_REGEX='(^|/)(\.git/|\..*\.swp$|\.tmp$|.*~$|\.~lock\..*|\.goutputstream-.*|\.DS_Store$)'

log "Monitoring '$SOURCE_DIR' for changes..."

inotifywait -m -r -q \
    -e create,delete,modify,move,attrib \
    --exclude "$EXCLUDE_REGEX" \
    "$SOURCE_DIR" | while read -r event; do
        log "Change detected: $event"
        # Debounce: wait for additional changes to settle
        while read -t "$DEBOUNCE_SECONDS" -r next_event; do
            # continue debouncing
            :
        done
        log "Debounce window elapsed. Triggering sync..."
        do_sync
    done
