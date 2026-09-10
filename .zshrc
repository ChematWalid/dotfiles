# ==============================================================================
#                      CATPPUCCIN MOCHA OH-MY-ZSH CONFIG
# ==============================================================================
# Master configuration file modularized into ~/.config/zsh/conf.d/
# Components:
#   • 00-env.zsh          — Environment variables, storage routes, PATH, editor
#   • 10-theme.zsh        — Catppuccin Mocha theme, Bat, Glow, Qt, FZF palette
#   • 20-options.zsh      — Shell options, pager scrolling, terminal column fixes
#   • 30-plugins.zsh      — Oh-My-Zsh plugins, completion styling, fzf-tab previews
#   • 40-tools.zsh        — Starship, Zoxide, Mise, Atuin, Carapace, Navi, Direnv
#   • 50-aliases.zsh      — All system, git, docker, media, and productivity aliases
#   • 99-local.zsh        — Machine-local overrides (optional)
# ==============================================================================

ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$HOME/.config/zsh/conf.d}"

if [[ -d "$ZSH_CONFIG_DIR" ]]; then
    for config_file in "$ZSH_CONFIG_DIR"/*.zsh(N); do
        [[ -r "$config_file" ]] && source "$config_file"
    done
    unset config_file
fi
