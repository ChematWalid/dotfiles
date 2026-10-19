#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# === Developer Environment & Caches ===
[[ -f "$HOME/.config/dotfiles-storage.env" ]] && source "$HOME/.config/dotfiles-storage.env"
if [[ -n "${HDD_MOUNT:-}" && -d "$HDD_MOUNT" ]]; then
    HDD="$HDD_MOUNT"
elif [[ -d "/mnt/drive2" ]]; then
    HDD="/mnt/drive2"
else
    HDD="$HOME"
fi

export CARGO_HOME="$HOME/.cargo"
export GOPATH="$HDD/go"
export PNPM_HOME="$HDD/.pnpm-store"
export PATH="$GOPATH/bin:$PNPM_HOME:$CARGO_HOME/bin:$HOME/.local/bin:$PATH"
export HF_HOME="$HDD/.cache/huggingface"
export ANDROID_HOME="$HDD/Android/Sdk"

# === Aliases ===
[[ -f "$HOME/.config/zsh/conf.d/50-aliases.zsh" ]] && source "$HOME/.config/zsh/conf.d/50-aliases.zsh"
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias cat='bat --theme="Catppuccin Mocha"'
alias grep='rg'
alias find='fd'
alias cd='z'

# Source generated shell integrations from cache; regenerate only after upgrades.
_source_cached_bash_init() {
    local tool="$1" cache="$2" binary temporary
    shift 2

    hash "$tool" 2>/dev/null || return 0
    binary=${BASH_CMDS["$tool"]:-}
    [[ -n "$binary" ]] || return 0

    if [[ ! -f "$cache" || "$cache" -ot "$binary" ]]; then
        mkdir -p "${cache%/*}" || return 1
        temporary=$(mktemp "${cache}.XXXXXX") || return 1
        if ! "$@" > "$temporary" 2>/dev/null; then
            rm -f -- "$temporary"
            return 1
        fi
        if ! mv -f -- "$temporary" "$cache"; then
            rm -f -- "$temporary"
            return 1
        fi
    fi

    source "$cache"
}

if [[ "${TERM:-dumb}" != dumb ]]; then
    _source_cached_bash_init starship \
        "${XDG_CACHE_HOME:-$HOME/.cache}/bash/starship/init.bash" \
        starship init bash || :
fi
_source_cached_bash_init zoxide \
    "${XDG_CACHE_HOME:-$HOME/.cache}/bash/zoxide/init.bash" \
    zoxide init bash || :
unset -f _source_cached_bash_init

export PATH=$PATH:/home/walid/.spicetify
export QT_QPA_PLATFORMTHEME=xdgdesktopportal
export QT_STYLE_OVERRIDE=kvantum

source /home/walid/.config/broot/launcher/bash/br

# Catppuccin Mocha FZF Theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--height 40% --layout=reverse --border rounded --inline-info"

export MANPATH="/home/walid/.local/share/man:$MANPATH"

# Bash has no unique-path attribute like zsh; deduplicate without subprocesses.
_dotfiles_dedupe_path() {
    local entry seen_empty=0
    local -a entries=() unique_entries=()
    local -A seen_entries=()

    IFS=: read -r -a entries <<< "$PATH"
    for entry in "${entries[@]}"; do
        if [[ -z "$entry" ]]; then
            ((seen_empty)) && continue
            seen_empty=1
        else
            [[ ${seen_entries["$entry"]+present} ]] && continue
            seen_entries["$entry"]=1
        fi
        unique_entries+=("$entry")
    done

    local IFS=:
    PATH="${unique_entries[*]}"
    export PATH
}
_dotfiles_dedupe_path
unset -f _dotfiles_dedupe_path
