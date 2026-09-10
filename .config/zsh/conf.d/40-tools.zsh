# ── Interactive CLI Integrations ──────────────────────────────────────────────
# Starship Catppuccin Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# Zoxide (Smart cd with memory)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# mise Runtime Manager (Node, Python, Go, Rust, etc.)
if command -v mise >/dev/null 2>&1; then
    export MISE_DATA_DIR="$HDD/.mise"
    export MISE_CACHE_DIR="$HDD/.cache/mise"
    eval "$(mise activate zsh)"
fi

# FZF keybindings (Ctrl+T for files, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh 2>/dev/null

# atuin (Contextual shell history, replaces Ctrl+R)
if command -v atuin >/dev/null 2>&1; then
    export ATUIN_NOBIND="false"
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# thefuck (Auto-correct failed commands with ESC ESC)
if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias)"
    fuck-command-line() { local cmd="$(fc -ln -1)"; local fixed="$(thefuck $cmd 2>/dev/null)"; [ -n "$fixed" ] && BUFFER="$fixed" && zle end-of-line; }
    zle -N fuck-command-line
    bindkey '\e\e' fuck-command-line
fi

# navi (Interactive Cheatsheet on Ctrl+G)
if command -v navi >/dev/null 2>&1; then
    eval "$(navi widget zsh)"
fi

# carapace (Smart Multi-Shell Completions for 1000+ CLI tools)
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash'
    source <(carapace _carapace zsh)
fi

# direnv (Auto-load .envrc per directory)
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# broot (br function for shell integration)
if [ -f ~/.config/broot/launcher/bash/br ]; then
    source ~/.config/broot/launcher/bash/br
fi
