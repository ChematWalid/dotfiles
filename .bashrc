#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# === Developer Environment & Caches on Drive D ===
export CARGO_HOME="$HOME/.cargo"
export PNPM_HOME="/mnt/drive2/.pnpm-store"
export PATH="$PNPM_HOME:$CARGO_HOME/bin:$HOME/.local/bin:$PATH"
export HF_HOME="/mnt/drive2/.cache/huggingface"
export ANDROID_HOME="/mnt/drive2/Android/Sdk"

# === Aliases ===
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
