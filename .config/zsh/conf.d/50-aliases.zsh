# ── Aliases & Function Shorthands ─────────────────────────────────────────────
# Modern Core CLI Replacements
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
alias bottom='btm'
alias md='glow -p'
alias tldr='tldr'
alias y='yazi'
alias copy='xclip -selection clipboard'
alias paste='xclip -selection clipboard -o'

# Trash CLI (Safe deletions to ~/.local/share/Trash)
alias tp='trash-put'
alias tl='trash-list'
alias trs='trash-restore'
alias te='trash-empty'

# Network & Connectivity
alias trip='trip'
alias traceroute='trip'
alias http='xh'
alias ping='gping'
alias dns='doggo'
alias dig='doggo'

# Media & Downloaders
alias ytdl='yt-dlp'
alias ytdl-mp3='yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-thumbnail --embed-metadata'
alias ytdl-best='yt-dlp -f "bestvideo+bestaudio/best" --embed-subs --embed-thumbnail --embed-metadata'
alias spot='spotdl'
alias gdl='gallery-dl'

# System & Package Management
alias cls='clear'
alias update='yay -Syu && sync-cheats'
alias cleanup='sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null; sudo paccache -r; yay -Sc --noconfirm'

# Text Processing & AST Search
alias sed='sd'
alias cut='choose'
alias sg='ast-grep'

# Containers & Self-Hosted Services
alias ld='lazydocker'
alias dgui='docker-gui'
alias dtop='ctop'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias vw='vaultwarden'
alias bw-local='bw config server https://localhost:8222'
alias genpass='bw generate -u -l -n -s --length 24'
alias genphrase='bw generate --passphrase --words 4 --separator -'

# Bitwarden Session Auto-Persistence
bw-unlock() {
    local session
    session=$(bw unlock --raw "$@")
    if [ -n "$session" ]; then
        export BW_SESSION="$session"
        echo "$BW_SESSION" > ~/.cache/.bw_session
        chmod 600 ~/.cache/.bw_session
        echo "✓ Bitwarden vault unlocked & session saved for all terminal tabs!"
    fi
}
if [ -f ~/.cache/.bw_session ] && [ -z "$BW_SESSION" ]; then
    export BW_SESSION=$(cat ~/.cache/.bw_session 2>/dev/null)
fi

# Antigravity AI CLI
alias agy-last='agy -c'
alias agy-ask='agy -p'

# TMUX
alias tm='tmux'
alias tma='tmux attach -t main 2>/dev/null || tmux new-session -s main'
alias tml='tmux list-sessions'
alias tmk='tmux kill-session -t'

# GitHub & Tunnels
alias ghd='gh dash'
alias tunnel='share-port'
alias share='share-port'
alias gg='gitui'

# Benchmarking & Translation
alias bench='hyperfine'
alias tr='trans'
alias trfr='trans :fr'
alias tren='trans :en'
alias trar='trans :ar'

# Tasks, Time & Calendar
alias t='task'
alias tw='timew'
alias cal='calcurse'
alias kc='khal interactive'
alias agenda='khal list'

# Music & Audio Visuals
alias music='ncmpcpp'
alias vis='cava'
alias sys='glances'

# File Managers & Archives
alias b='br'
alias lf='lf'
alias unpack='ouch decompress'
alias pack='ouch compress'
alias dust='dust -r'
alias vd='visidata'

# Cloud Sync (rclone)
alias rc='rclone'
alias rcs='rclone sync'
alias rccp='rclone copy'
alias rcls='rclone ls'

# Fun & ASCII Art
alias banner='figlet'
alias cbanner='toilet -f future'
alias rainbow='lolcat'
alias box='boxes -d stone'
alias matrix='cmatrix -b -C cyan'
alias bonsai='cbonsai -l -t 0.05'
alias aquarium='asciiquarium'

# Communication
alias telegram='ayugram'
alias telegram-desktop='ayugram'
