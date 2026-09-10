# ── Core Environment & Developer Storage ──────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode reminder
ZSH_DISABLE_COMPFIX="true"

# === Developer Environment & HDD Cache Routing ===
[[ -f "$HOME/.config/dotfiles-storage.env" ]] && source "$HOME/.config/dotfiles-storage.env"

if [[ -n "${HDD_MOUNT:-}" && -d "$HDD_MOUNT" ]]; then
    HDD="$HDD_MOUNT"
elif [[ -d "/mnt/drive2" ]]; then
    HDD="/mnt/drive2"
else
    HDD="$HOME"
fi

# ── Rust ──
export CARGO_HOME="$HOME/.cargo"

# ── Python / uv ──
export UV_CACHE_DIR="$HDD/.cache/uv"
export PIP_CACHE_DIR="$HDD/.cache/pip"
export PIPX_HOME="$HDD/.local/pipx"

# ── Node / npm / pnpm ──
export PNPM_HOME="$HDD/.pnpm-store"
export npm_config_cache="$HDD/.cache/npm"
export NODE_EXTRA_CA_CERTS="/mnt/drive2/docker-data/vaultwarden/ssl/cert.pem"
export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

# ── Go ──
export GOPATH="$HDD/go"
export GOCACHE="$HDD/.cache/go-build"

# ── AI / ML ──
export HF_HOME="$HDD/.cache/huggingface"
export TORCH_HOME="$HDD/.cache/torch"
export XDG_CACHE_HOME="$HOME/.cache"

# ── Mobile dev ──
export ANDROID_HOME="$HDD/Android/Sdk"
export GRADLE_USER_HOME="$HDD/.gradle"

# ── Gems / Ruby ──
export GEM_HOME="$HDD/.gems"
export GEM_PATH="$HDD/.gems"

# ── PATH & Default Editor ──
export PATH="$HOME/.ghcup/bin:$HOME/.nimble/bin:$HOME/.spicetify:$PNPM_HOME:$CARGO_HOME/bin:$HOME/.local/bin:$GEM_HOME/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
