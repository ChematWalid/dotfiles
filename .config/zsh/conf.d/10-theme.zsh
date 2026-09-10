# ── Theming Defaults (Catppuccin Mocha) ──────────────────────────────────────
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

# Syntax Highlighting Catppuccin Mocha
if [ -f "$ZSH_CUSTOM/plugins/catppuccin-syntax-highlighting/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_CUSTOM/plugins/catppuccin-syntax-highlighting/catppuccin_mocha-zsh-syntax-highlighting.zsh"
fi
