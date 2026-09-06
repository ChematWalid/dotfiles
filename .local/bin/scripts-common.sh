#!/usr/bin/env bash
# ── scripts-common.sh ─────────────────────────────────────────────────────────
# Shared utilities, Catppuccin Mocha colors, and safety primitives for shell scripts.

# ── Catppuccin Mocha Colors (ANSI & Hex) ──────────────────────────────────────
readonly HEX_ROSEWATER="#f5e0dc"
readonly HEX_FLAMINGO="#f2cdcd"
readonly HEX_PINK="#f5c2e7"
readonly HEX_MAUVE="#cba6f7"
readonly HEX_RED="#f38ba8"
readonly HEX_MAROON="#eba0ac"
readonly HEX_PEACH="#fab387"
readonly HEX_YELLOW="#f9e2af"
readonly HEX_GREEN="#a6e3a1"
readonly HEX_TEAL="#94e2d5"
readonly HEX_SKY="#89dceb"
readonly HEX_SAPPHIRE="#74c7ec"
readonly HEX_BLUE="#89b4fa"
readonly HEX_LAVENDER="#b4befe"
readonly HEX_TEXT="#cdd6f4"
readonly HEX_SUBTEXT1="#bac2de"
readonly HEX_SUBTEXT0="#a6adc8"
readonly HEX_OVERLAY2="#9399b2"
readonly HEX_OVERLAY1="#7f849c"
readonly HEX_OVERLAY0="#6c7086"
readonly HEX_SURFACE2="#585b70"
readonly HEX_SURFACE1="#45475a"
readonly HEX_SURFACE0="#313244"
readonly HEX_BASE="#1e1e2e"
readonly HEX_MANTLE="#181825"
readonly HEX_CRUST="#11111b"

# ── Notification Helper ───────────────────────────────────────────────────────
notify() {
    local urgency="${1:-normal}"
    local title="$2"
    local body="${3:-}"
    local timeout="${4:-4000}"
    local icon="${5:-dialog-information}"

    notify-send \
        -u "$urgency" \
        -t "$timeout" \
        -i "$icon" \
        "$title" \
        "$body" 2>/dev/null || true
}

# ── Safe Single-Instance Lock Helper ──────────────────────────────────────────
# Usage:
#   acquire_lock "/tmp/.my-script.lock"
#   trap 'release_lock "/tmp/.my-script.lock"' EXIT INT TERM
acquire_lock() {
    local lockfile="$1"
    if [[ -f "$lockfile" ]]; then
        local old_pid
        old_pid=$(cat "$lockfile" 2>/dev/null || true)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            return 1
        fi
    fi
    echo "$$" > "$lockfile"
    return 0
}

release_lock() {
    local lockfile="$1"
    if [[ -f "$lockfile" ]]; then
        local holder
        holder=$(cat "$lockfile" 2>/dev/null || true)
        if [[ "$holder" == "$$" ]]; then
            rm -f "$lockfile"
        fi
    fi
}
