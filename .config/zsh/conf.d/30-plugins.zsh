# ── Oh-My-Zsh Plugins & Completion Styling ────────────────────────────────────
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

# Custom completions directory
fpath=(~/.zsh/completions $fpath)

# Load Oh-My-Zsh
[ -s "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# === Smart Completion & FZF-Tab Settings ===
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format '[%d (errors: %e)]'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'

# Clean up fzf-tab group display
zstyle ':fzf-tab:*' show-group quiet
zstyle ':fzf-tab:*' single-group ''

# Case-insensitive, partial-word, and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# Force zsh not to show completion menu, allow fzf-tab to capture
zstyle ':completion:*' menu no

# Custom popup styling for fzf-tab
zstyle ':fzf-tab:*' fzf-flags '--color=bg+:#313244,bg:#1e1e2e,fg:#cdd6f4,hl:#f38ba8,prompt:#cba6f7' '--preview-window=right:60%:wrap'
zstyle ':fzf-tab:*' fzf-pad 4

# Preview command documentation + dynamic category indicator for currently highlighted command
zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
    '[[ -n "$group" ]] && printf "\033[1;35mCategory:\033[0m %s\n\n" "$group"; (out=$(tldr --color always "$word" 2>/dev/null) && [[ -n "$out" ]] && echo "$out") || (whatis "$word" 2>/dev/null) || (man "$word" 2>/dev/null | col -bx | head -n 35) || ($word --help 2>&1 | head -n 35)'

# Preview subcommands & options with dynamic category indicator, clean description & tldr docs
zstyle ':fzf-tab:complete:*:*' fzf-preview \
    'if [ -d "$realpath" ]; then eza -1 --color=always "$realpath"; elif [ -f "$realpath" ]; then bat --style=plain --color=always --line-range :100 "$realpath" 2>/dev/null || cat "$realpath"; elif [[ -n "$group" || -n "$desc" ]]; then [[ -n "$group" ]] && printf "\033[1;35mCategory:\033[0m %s\n\n" "$group"; clean_desc="${desc#* -- }"; [[ -n "$clean_desc" ]] && printf "\033[1;36mSummary:\033[0m %s\n\n" "$clean_desc"; (cmd="${BUFFER%% *}"; tldr --color always "${cmd}-${word}" 2>/dev/null || tldr --color always "$word" 2>/dev/null) || true; fi'

# Preview process info when completing kill / pkill / killall
zstyle ':fzf-tab:complete:(kill|pkill|killall):*' fzf-preview 'ps -p $word -o pid,user,%cpu,%mem,command 2>/dev/null || true'

# Preview systemd unit status when completing systemctl
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null'

# Preview git show / log for git diff / checkout
zstyle ':fzf-tab:complete:git-(log|diff|show):*' fzf-preview 'git show --color=always $word 2>/dev/null'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --color=always -n 10 --oneline $word 2>/dev/null'

# === Smart Auto-suggestions (Predictive Completion First, then History) ===
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
ZSH_AUTOSUGGEST_STRATEGY=(completion history)
ZSH_AUTOSUGGEST_USE_ASYNC=1
