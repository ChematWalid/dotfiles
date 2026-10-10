# ── Terminal Options & Behavior ───────────────────────────────────────────────
# Fix COLUMNS on window resize without running subshells on every prompt
TRAPWINCH() {
    COLUMNS=$(tput cols 2>/dev/null || echo 80)
}

# Smooth mouse scrolling for pagers (git diff, git log, man, systemctl)
export LESS="--mouse --wheel-lines=1 -R -F -X"
export SYSTEMD_LESS="--mouse --wheel-lines=1 -R -F -X"
