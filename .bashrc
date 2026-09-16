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

# === Starship & Zoxide Init ===
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init bash)"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

export PATH=$PATH:/home/walid/.spicetify
export QT_QPA_PLATFORMTHEME=qt6ct
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