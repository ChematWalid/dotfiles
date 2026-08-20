# ==============================================================================
#                      CATPPUCCIN MOCHA OH-MY-ZSH CONFIG
# ==============================================================================

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme (Empty to use Starship Catppuccin prompt)
ZSH_THEME=""

# Enable case-sensitive completion.
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"

# Update settings
zstyle ':omz:update' mode reminder

# === Developer Environment & Caches on Drive D ===
export CARGO_HOME="$HOME/.cargo"
export PNPM_HOME="/mnt/drive2/.pnpm-store"
export PATH="$PNPM_HOME:$CARGO_HOME/bin:$HOME/.local/bin:$PATH"
export HF_HOME="/mnt/drive2/.cache/huggingface"
export ANDROID_HOME="/mnt/drive2/Android/Sdk"
export EDITOR="nvim"
export VISUAL="nvim"

# === Theming Defaults (Catppuccin Mocha) ===
export BAT_THEME="Catppuccin Mocha"
export GLOW_STYLE="dark"
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_STYLE_OVERRIDE=kvantum

# FZF Catppuccin Mocha Colors & Defaults
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--height 40% --layout=reverse --border rounded --inline-info"

# Use fd and fzf defaults
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
fi

# === Oh-My-Zsh Plugins ===
plugins=(
    git
    sudo
    extract
    colored-man-pages
    copypath
    copyfile
    fzf-tab
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-completions
)

# Load Oh-My-Zsh
[ -s "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# === Smart Completion & FZF-Tab Settings ===
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Force zsh not to show completion menu, allow fzf-tab to capture
zstyle ':completion:*' menu no
# Preview directory contents with eza when completing cd / z
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
# Preview file content with bat
zstyle ':fzf-tab:complete:*:*' fzf-preview 'if [ -d "$realpath" ]; then eza -1 --color=always "$realpath"; elif [ -f "$realpath" ]; then bat --style=plain --color=always --line-range :100 "$realpath" 2>/dev/null || cat "$realpath"; fi'
# Custom popup styling for fzf-tab
zstyle ':fzf-tab:*' fzf-flags '--color=bg+:#313244,bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,prompt:#cba6f7'

# === Smart Auto-suggestions (History + Zsh Smart Completions) ===
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1

# === Syntax Highlighting Catppuccin Mocha ===
if [ -f "$ZSH_CUSTOM/plugins/catppuccin-syntax-highlighting/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_CUSTOM/plugins/catppuccin-syntax-highlighting/catppuccin_mocha-zsh-syntax-highlighting.zsh"
fi

# === Starship & Zoxide Init ===
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

# FZF keybindings (Ctrl+T for files, Ctrl+R for history, Alt+C for cd)
source /usr/share/fzf/key-bindings.zsh 2>/dev/null
source /usr/share/fzf/completion.zsh 2>/dev/null

# === Aliases for Modern CLI Tools ===
# Modern Replacements
alias ls='eza --icons --group-directories-first'
alias ll='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias cd='z'
alias vim='nvim'
alias v='nvim'
alias lg='lazygit'
alias df='duf'
alias du='gdu'
alias ps='procs'
alias top='btop'
alias htop='btop'
alias md='glow'
alias tldr='tealdeer'
alias y='yazi'
alias copy='xclip -selection clipboard'
alias paste='xclip -selection clipboard -o'

# System & Package Management
alias cls='clear'
alias update='yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo paccache -r; yay -Sc --noconfirm'
