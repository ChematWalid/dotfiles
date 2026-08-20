# Catppuccin Mocha Zsh Configuration
export ZSH_THEME=""

# === Developer Environment & Caches on Drive D ===
export CARGO_HOME="$HOME/.cargo"
export PNPM_HOME="/mnt/drive2/.pnpm-store"
export PATH="$PNPM_HOME:$CARGO_HOME/bin:$HOME/.local/bin:$PATH"
export HF_HOME="/mnt/drive2/.cache/huggingface"
export ANDROID_HOME="/mnt/drive2/Android/Sdk"

# === Aliases ===
alias cls='clear'
alias update='yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo paccache -r; yay -Sc --noconfirm'
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias cat='bat --theme="Catppuccin Mocha"'
alias grep='rg'
alias find='fd'
alias cd='z'
alias vim='nvim'
alias v='nvim'

# === History ===
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# === Starship & Zoxide Init ===
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# Starship prompt
eval "$(starship init zsh)"

# zoxide (smarter cd)
eval "$(zoxide init zsh)"

# fzf keybindings
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh 2>/dev/null

# Better aliases
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias cd='z'

# FZF Catppuccin Mocha theme
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_STYLE_OVERRIDE=kvantum

# === Zsh Autosuggestions & Syntax Highlighting ===
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Enable completion system
autoload -Uz compinit && compinit -C

# Load completions, autosuggestions and syntax-highlighting
[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
