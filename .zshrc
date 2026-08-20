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
alias tldr='tldr'   # tealdeer package; binary is 'tldr'
alias y='yazi'
alias copy='xclip -selection clipboard'
alias paste='xclip -selection clipboard -o'

# Media & Downloaders
alias ytdl='yt-dlp'
alias ytdl-mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata'
alias ytdl-best='yt-dlp -f "bestvideo+bestaudio/best" --embed-subs --embed-thumbnail --embed-metadata'
alias spot='spotdl'
alias gdl='gallery-dl'

# System & Package Management
alias cls='clear'
alias update='yay -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo paccache -r; yay -Sc --noconfirm'

# ── Text Processing (sd, choose, gron, miller, xsv, grex) ─────────────────
alias sed='sd'                            # sd 'old' 'new' file  (simpler sed)
alias cut='choose'                        # choose 0 2  (friendlier cut/awk)
# gron file.json | grep "name"           # make JSON greppable
# mlr --csv filter '$col > 5' file.csv   # awk for CSV/JSON/TSV
# xsv stats file.csv                     # fast CSV stats/slice/join
# grex "abc" "abbc" "abccc"             # auto-generate regex from examples
# fselect "name FROM /home WHERE size > 1mb"  # SQL-like file search

# ── Search ─────────────────────────────────────────────────────────────────
alias sg='ast-grep'                       # ast-grep: code-structure-aware search
# sg 'console.log($ARG)' --lang js        # find by AST pattern
# plocate filename                        # fast file locate (updatedb to refresh)

# ── Dev Tools ──────────────────────────────────────────────────────────────
alias ld='lazydocker'                     # Docker TUI (like lazygit for Docker)
# gh pr create / gh issue list / gh run watch  — GitHub CLI (already on PATH)

# ── Benchmarking ───────────────────────────────────────────────────────────
# hyperfine 'command1' 'command2'        # benchmark with statistics
alias bench='hyperfine'

# ── Translation ────────────────────────────────────────────────────────────
alias tr='trans'                          # trans en:fr "hello world"
alias trfr='trans :fr'                   # translate anything to French
alias tren='trans :en'                   # translate anything to English
alias trar='trans :ar'                   # translate anything to Arabic

# ── Tasks & Time ───────────────────────────────────────────────────────────
# task add "Buy groceries" due:tomorrow  # add a task
# task next                              # see priority tasks
# task 1 done                            # mark done
# timew start coding                     # start time tracking
# timew stop                             # stop tracking
# timew summary                          # see time logged this week
alias t='task'                           # quick task shorthand
alias tw='timew'                         # quick timewarrior shorthand

# ── Calendar ───────────────────────────────────────────────────────────────
alias cal='calcurse'                     # TUI calendar + todos + appointments
alias kc='khal interactive'              # khal TUI (CalDAV-sync capable)
alias agenda='khal list'                 # quick agenda view

# ── Music (MPD + ncmpcpp) ──────────────────────────────────────────────────
# mpd                   — start music player daemon (or: systemctl --user enable --now mpd)
# ncmpcpp               — open TUI music player
# mpc play/pause/next   — quick MPD control from any terminal
alias music='ncmpcpp'                    # open music TUI
alias vis='cava'                         # audio visualizer (Catppuccin Mocha gradient)

# ── Images / Video in Terminal ─────────────────────────────────────────────
# timg image.png         — show image inline in terminal
# timg video.mp4         — show video inline (with -g for size)
# chafa image.png        — unicode/sixel image (already installed)

# ── Monitoring ─────────────────────────────────────────────────────────────
alias sys='glances'                      # all-in-one system overview

# ── ASCII Tools ────────────────────────────────────────────────────────────
# Text → ASCII banners
alias banner='figlet'                     # figlet "Hello"  (plain ASCII)
alias cbanner='toilet -f future'          # toilet colored banner (try: -f mono12 -F gay)
alias rainbow='lolcat'                    # pipe anything: ls | lolcat
alias box='boxes -d stone'               # echo "text" | boxes  (try: -d peek, -d parchment)

# Image → ASCII
# jp2a image.jpg                          # image → ASCII (monochrome)
# ascii-image-converter image.png -C      # image → colored ASCII  (-b for braille)
# chafa image.png                         # image → hi-res unicode/sixel in terminal

# Character lookup
# ascii a                                 # show all aliases for char 'a'
# ascii -d                                # full decimal table
# ascii -x                                # full hex table

# Fun / Animated
alias matrix='cmatrix -b -C cyan'        # matrix rain  (-C for color, -b bold)
alias bonsai='cbonsai -l -t 0.05'        # animated growing bonsai
alias aquarium='asciiquarium'            # fish tank
# pipes.sh                               # flowing ASCII pipes screensaver

# Record terminal (share as ASCII animation)
# asciinema rec demo.cast                # start recording
# asciinema play demo.cast               # play it back
# asciinema upload demo.cast             # upload to asciinema.org

# ── File Managers ──────────────────────────────────────────────────────────
alias b='br'                              # broot shorthand (br = shell-integrated cd)
alias lf='lf'                             # lf file manager
# alias y='yazi'                          # yazi already set above; prefer yazi or lf/br as you like

# ── Archive (ouch) ─────────────────────────────────────────────────────────
alias unpack='ouch decompress'            # ouch decompress archive.tar.gz
alias pack='ouch compress'               # ouch compress files... output.tar.gz

# ── Disk Usage ─────────────────────────────────────────────────────────────
alias dust='dust -r'                      # dust (reversed = biggest at bottom)

# ── Network Tools ──────────────────────────────────────────────────────────
alias http='xh'                           # xh = httpie-compatible but faster
alias ping='gping'                        # gping shows a graph over time
alias dns='dog'                           # dog = colorful dig replacement
# bandwhich needs sudo: sudo bandwhich

# ── Git ────────────────────────────────────────────────────────────────────
alias gg='gitui'                          # gitui TUI (alt to lazygit)
# lg = lazygit (already set above)

# ── Data / Config ──────────────────────────────────────────────────────────
# dasel: query/edit JSON,YAML,TOML,XML
# visidata: open any CSV/JSON/SQL as TUI spreadsheet (vd file.csv)
alias vd='visidata'

# ── Cloud Sync (rclone) ────────────────────────────────────────────────────
# Setup: rclone config  (add Google Drive, Mega, S3, etc.)
alias rc='rclone'
alias rcs='rclone sync'                   # one-way sync  (careful!)
alias rccp='rclone copy'                  # safe copy
alias rcls='rclone ls'                    # list remote

# ── Media & Downloaders ────────────────────────────────────────────────────
alias ytdl='yt-dlp'
alias ytdl-mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata'
alias ytdl-best='yt-dlp -f "bestvideo+bestaudio/best" --embed-subs --embed-thumbnail --embed-metadata'
alias spot='spotdl'
alias gdl='gallery-dl'

# ── navi — Interactive Cheatsheet (Ctrl+G) ─────────────────────────────────
if command -v navi >/dev/null 2>&1; then
    eval "$(navi widget zsh)"
fi

# ── carapace — Smart Multi-Shell Completions ───────────────────────────────
# Covers 1000+ CLI tools (git, docker, kubectl, ffmpeg, etc.)
if command -v carapace >/dev/null 2>&1; then
    export CARAPACE_BRIDGES='zsh,fish'
    zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
    source <(carapace _carapace zsh)
fi

# ── direnv — Auto-load .envrc in project dirs ──────────────────────────────
# Usage: echo 'export API_KEY=xxx' > .envrc && direnv allow
if command -v direnv >/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
fi

# ── broot — br() shell function for cd integration ─────────────────────────
# First run: broot --install (writes br function to this file automatically)
if [ -f ~/.config/broot/launcher/bash/br ]; then
    source ~/.config/broot/launcher/bash/br
fi
