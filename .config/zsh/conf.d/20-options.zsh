# ── Terminal Options & Behavior ───────────────────────────────────────────────
# Fix COLUMNS not being set correctly (especially in tmux)
precmd_fix_columns() { COLUMNS=$(tput cols) }
precmd_functions+=(precmd_fix_columns)

# Smooth mouse scrolling for pagers (git diff, git log, man, systemctl)
export LESS="--mouse --wheel-lines=1 -R -F -X"
export SYSTEMD_LESS="--mouse --wheel-lines=1 -R -F -X"
