#!/usr/bin/env bash
# ── scripts-common.sh ─────────────────────────────────────────────────────────
# Shared utilities, Catppuccin Mocha colors, and safety primitives for shell scripts.

# ── Catppuccin Mocha Colors (Hex) ─────────────────────────────────────────────
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

# ── Standard Runtime Directory ────────────────────────────────────────────────
get_dotfiles_runtime_dir() {
    local rtd="${XDG_RUNTIME_DIR:-${HOME}/.cache}/dotfiles"
    mkdir -p "$rtd"
    printf '%s\n' "$rtd"
}

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

# ── Atomic Single-Instance Lock Helper (util-linux flock) ─────────────────────
# Usage:
#   acquire_flock 9 "/path/to/script.lock" [timeout_secs] || exit 0
# The lock is automatically released by the kernel when the process terminates.
acquire_flock() {
    local fd="${1:-9}"
    local lockfile="$2"
    local timeout="${3:-0}"

    mkdir -p "$(dirname "$lockfile")"
    eval "exec ${fd}>\"\$lockfile\""

    if (( timeout > 0 )); then
        flock -w "$timeout" "$fd"
    else
        flock -n "$fd"
    fi
}

release_flock() {
    local fd="${1:-9}"
    flock -u "$fd" 2>/dev/null || true
}
