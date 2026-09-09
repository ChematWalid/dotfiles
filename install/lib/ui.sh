#!/usr/bin/env bash
# ── install/lib/ui.sh ─────────────────────────────────────────────────────────
# Terminal colors, logging functions, and interactive prompt helpers
# ─────────────────────────────────────────────────────────────────────────────

# ANSI Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
BOLD='\033[1m'; RESET='\033[0m'

log()   { echo -e "${GREEN}[✓]${RESET} $*"; }
info()  { echo -e "${BLUE}[→]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; }
step()  { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

print_banner() {
  echo -e "${BOLD}"
  echo "  ╔══════════════════════════════════════════════════════╗"
  echo "  ║      Catppuccin Mocha Desktop — Restore Engine       ║"
  echo "  ║      github.com/ChematWalid/dotfiles                 ║"
  echo "  ╚══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo "  Dotfiles directory : $DOTFILES_DIR"
  echo "  Target home        : $HOME"
  echo ""
}

# Prompt helper
# Usage: prompt_yn "Do you want to install X?" "y" (or "n")
# Returns 0 for Yes, 1 for No.
# Under "all" mode, always returns 0 (Yes).
# Under "dotfiles" mode, always returns 1 (No) for non-dotfile steps.
prompt_yn() {
  local prompt_text="$1"
  local default_val="${2:-y}"

  if [[ "${INSTALL_MODE:-}" == "all" || "${INSTALL_MODE:-}" == "module" ]]; then
    return 0
  fi
  if [[ "${INSTALL_MODE:-}" == "dotfiles" ]]; then
    return 1
  fi

  local choices="[Y/n]"
  [[ "$default_val" == "n" ]] && choices="[y/N]"

  local resp=""
  echo -ne "  ${BOLD}${YELLOW}?${RESET} ${prompt_text} ${CYAN}${choices}${RESET} "
  read -r resp || true
  resp="${resp:-$default_val}"
  if [[ "${resp,,}" == "y"* ]]; then
    return 0
  else
    return 1
  fi
}
