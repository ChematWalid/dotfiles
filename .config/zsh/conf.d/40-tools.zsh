# ── Interactive CLI Integrations ──────────────────────────────────────────────
# Helper function to cache CLI tool init scripts with bytecode compilation
# Automatically regenerates and recompiles when the tool binary is updated
_source_cached() {
    local tool="$1"
    local cache="$2"
    shift 2
    local bin="${commands[$tool]-}"
    [[ -n "$bin" ]] || return 1
    if [[ ! -f "$cache" || "$cache" -ot "$bin" ]]; then
        mkdir -p "${cache:h}"
        "$@" > "$cache" 2>/dev/null
        zcompile -R "$cache" 2>/dev/null
    fi
    source "$cache"
}

# Starship Catppuccin Prompt
if [[ "${TERM:-dumb}" != dumb ]]; then
    _source_cached starship "${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh" starship init zsh
fi

# Zoxide (Smart cd with memory)
_source_cached zoxide "${XDG_CACHE_HOME:-$HOME/.cache}/zoxide/init.zsh" zoxide init zsh

# mise Runtime Manager (Ultra-fast startup via shims + on-demand chpwd hook)
if command -v mise >/dev/null 2>&1; then
    export MISE_DATA_DIR="$HDD/.mise"
    export MISE_CACHE_DIR="$HDD/.cache/mise"
    export PATH="$MISE_DATA_DIR/shims:$PATH"

    mise() {
        case "$1" in
            deactivate|shell|sh) eval "$(command mise "$@")" ;;
            *) command mise "$@" ;;
        esac
    }

    _mise_chpwd() {
        eval "$(command mise hook-env --shell-pid $$ -s zsh 2>/dev/null)"
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd _mise_chpwd
fi

# FZF keybindings (Ctrl+T for files, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh 2>/dev/null

# atuin (Contextual shell history, replaces Ctrl+R)
if command -v atuin >/dev/null 2>&1; then
    export ATUIN_NOBIND="false"
    _source_cached atuin "${XDG_CACHE_HOME:-$HOME/.cache}/atuin/init.zsh" atuin init zsh --disable-up-arrow
fi

# thefuck (Native function avoids 200ms+ Python startup on shell launch)
if command -v thefuck >/dev/null 2>&1; then
    fuck() {
        TF_PYTHONIOENCODING=$PYTHONIOENCODING
        export TF_SHELL=zsh
        export TF_ALIAS=fuck
        TF_SHELL_ALIASES=$(alias)
        export TF_SHELL_ALIASES
        TF_HISTORY="$(fc -ln -10)"
        export TF_HISTORY
        export PYTHONIOENCODING=utf-8
        TF_CMD=$(thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@") && eval "$TF_CMD"
        unset TF_HISTORY
        export PYTHONIOENCODING=$TF_PYTHONIOENCODING
        test -n "$TF_CMD" && print -s "$TF_CMD"
    }
    fuck-command-line() {
        local cmd="$(fc -ln -1)"
        local fixed="$(thefuck "$cmd" 2>/dev/null)"
        [ -n "$fixed" ] && BUFFER="$fixed" && zle end-of-line
    }
    zle -N fuck-command-line
    bindkey '\e\e' fuck-command-line
fi

# navi (Interactive Cheatsheet on Ctrl+G)
_source_cached navi "${XDG_CACHE_HOME:-$HOME/.cache}/navi/init.zsh" navi widget zsh

# carapace (Smart Multi-Shell Completions for 1000+ CLI tools)
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish,bash'
    _source_cached carapace "${XDG_CACHE_HOME:-$HOME/.cache}/carapace/init.zsh" carapace _carapace zsh
fi

# direnv (Auto-load .envrc per directory)
_source_cached direnv "${XDG_CACHE_HOME:-$HOME/.cache}/direnv/init.zsh" direnv hook zsh

# broot (br function for shell integration)
if [ -f ~/.config/broot/launcher/bash/br ]; then
    source ~/.config/broot/launcher/bash/br
fi
