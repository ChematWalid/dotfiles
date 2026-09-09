#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
#  install.sh — Arch Linux Catppuccin Mocha Desktop Restore Engine
#  Repo: https://github.com/ChematWalid/dotfiles
#
#  Usage:
#    bash install.sh [OPTIONS]
#
#  Options:
#    -y, --all, --full      Install everything automatically without prompts (Accept all)
#    -i, --custom           Interactive mode: choose which tools & categories to install
#    -d, --dotfiles-only    Only symlink configs & dotfiles (Refuse all package downloads)
#    -m, --module <name>    Run a single specific module (e.g. -m desktop-tools, -m fonts)
#    -l, --list             List all available modules
#    -h, --help             Show help documentation
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WHOAMI="$(whoami)"

# ── Source Library Modules ───────────────────────────────────────────────────
source "$DOTFILES_DIR/install/lib/ui.sh"
source "$DOTFILES_DIR/install/lib/link.sh"
source "$DOTFILES_DIR/install/lib/storage.sh"
source "$DOTFILES_DIR/install/lib/summary.sh"

# ── Safety Check ─────────────────────────────────────────────────────────────
if [[ ! -f "$DOTFILES_DIR/pkglist-pacman-names.txt" ]]; then
  error "Run this from the dotfiles directory: cd ~/dotfiles && bash install.sh"
  exit 1
fi

# ── Discover Modules ─────────────────────────────────────────────────────────
MODULE_FILES=()
for mod in "$DOTFILES_DIR/install/modules"/*.sh; do
  [[ -f "$mod" ]] && MODULE_FILES+=("$mod")
done

# ── Helper: List Modules ─────────────────────────────────────────────────────
list_modules() {
  echo -e "${BOLD}${CYAN}Available Installation Modules:${RESET}\n"
  for mod in "${MODULE_FILES[@]}"; do
    (
      source "$mod"
      local num
      num=$(basename "$mod" | cut -d'-' -f1)
      printf "  ${BOLD}${GREEN}[%-2s]${RESET} ${BOLD}%-18s${RESET} — %s\n" \
        "$num" "${MODULE_ID}" "${MODULE_DESC}"
    )
  done
  echo ""
  exit 0
}

# ── Help Documentation ───────────────────────────────────────────────────────
show_help() {
  echo -e "${BOLD}${MAGENTA}Catppuccin Mocha Desktop Restore Engine${RESET}
Repository: https://github.com/ChematWalid/dotfiles

${BOLD}USAGE:${RESET}
  bash install.sh [OPTIONS]

${BOLD}OPTIONS:${RESET}
  ${GREEN}-y, --all, --full${RESET}      Install everything automatically without prompts (Accept all)
  ${GREEN}-i, --custom${RESET}           Interactive mode: choose which tools and components to install
  ${GREEN}-d, --dotfiles-only${RESET}    Only symlink configuration files in ~/.config and ~/.local (Refuse packages)
  ${GREEN}-m, --module <id>${RESET}      Execute a single specific module only (e.g. -m desktop-tools)
  ${GREEN}-l, --list${RESET}             List all available modules and descriptions
  ${GREEN}-h, --help${RESET}             Show this help message and exit

${BOLD}INTERACTIVE MODES:${RESET}
  Running without flags opens an interactive menu where you can:
  • Accept all tools & packages
  • Selectively accept or refuse individual tools (TeX Live, SongRec, Telegram forks, etc.)
  • Refuse all package downloads and only link dotfiles
  • Pick and execute any single module directly
"
  exit 0
}

# ── Parse CLI Arguments ──────────────────────────────────────────────────────
INSTALL_MODE=""
TARGET_MODULE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--all|--full|--yes)
      INSTALL_MODE="all"
      shift
      ;;
    -i|--custom|--interactive)
      INSTALL_MODE="custom"
      shift
      ;;
    -d|--dotfiles-only)
      INSTALL_MODE="dotfiles"
      shift
      ;;
    -m|--module)
      TARGET_MODULE="$2"
      INSTALL_MODE="module"
      shift 2
      ;;
    -l|--list|--modules)
      list_modules
      ;;
    -h|--help)
      show_help
      ;;
    *)
      error "Unknown option: $1"
      echo "Run './install.sh --help' for usage."
      exit 1
      ;;
  esac
done

# ── Interactive Mode Banner ──────────────────────────────────────────────────
print_banner

if [[ -z "$INSTALL_MODE" ]]; then
  echo -e "${BOLD}${CYAN}Select installation mode:${RESET}"
  echo -e "  ${BOLD}[1] All (Full Restore)${RESET}   — Install all packages, tools, and configs automatically"
  echo -e "  ${BOLD}[2] Custom (Interactive)${RESET}  — Choose which tools and categories to install or refuse"
  echo -e "  ${BOLD}[3] Dotfiles Only${RESET}         — Symlink configs only (Skip all package & binary downloads)"
  echo -e "  ${BOLD}[4] Pick Single Module${RESET}    — Execute one specific module"
  echo -e "  ${BOLD}[q] Quit${RESET}                  — Abort installer without making any changes"
  echo ""
  read -rp "  Enter choice [1/2/3/4/q, default: 1]: " mode_choice || true
  case "${mode_choice,,}" in
    1|""|"a"|"all")
      INSTALL_MODE="all"
      ;;
    2|"c"|"custom"|"i")
      INSTALL_MODE="custom"
      ;;
    3|"d"|"dotfiles"|"dotfiles-only")
      INSTALL_MODE="dotfiles"
      ;;
    4|"p"|"module")
      INSTALL_MODE="module"
      echo ""
      list_modules_interactive() {
        for mod in "${MODULE_FILES[@]}"; do
          (
            source "$mod"
            local num
            num=$(basename "$mod" | cut -d'-' -f1)
            printf "  ${BOLD}[%-2s]${RESET} %-18s — %s\n" "$num" "$MODULE_ID" "$MODULE_NAME"
          )
        done
      }
      list_modules_interactive
      echo ""
      read -rp "  Enter module ID or number: " TARGET_MODULE || true
      ;;
    q|"quit"|"exit")
      echo "Installation cancelled."
      exit 0
      ;;
    *)
      warn "Unknown choice '$mode_choice'; defaulting to [2] Custom."
      INSTALL_MODE="custom"
      ;;
  esac
fi

log "Active mode: ${BOLD}${INSTALL_MODE^^}${RESET}"

# ── Storage Configuration ────────────────────────────────────────────────────
configure_storage

# ── Module Execution Engine ──────────────────────────────────────────────────
run_single_module() {
  local target="$1"
  local matched=false
  for mod in "${MODULE_FILES[@]}"; do
    (
      source "$mod"
      local num
      num=$(basename "$mod" | cut -d'-' -f1)
      if [[ "$MODULE_ID" == "$target" || "$num" == "$target" || "$(basename "$mod" .sh)" == *"$target"* ]]; then
        info "Running module: ${BOLD}$MODULE_NAME${RESET} ($MODULE_ID)"
        run_module
        exit 0
      fi
      exit 1
    ) && { matched=true; break; }
  done

  if ! $matched; then
    error "Module '$target' not found."
    echo "Run './install.sh --list' to see all available module IDs."
    exit 1
  fi
}

if [[ "$INSTALL_MODE" == "module" ]]; then
  if [[ -z "$TARGET_MODULE" ]]; then
    error "No module specified."
    exit 1
  fi
  run_single_module "$TARGET_MODULE"
  print_summary
  exit 0
fi

# Run all modules matching current mode
for mod in "${MODULE_FILES[@]}"; do
  (
    source "$mod"
    # Skip modules that are not compatible with dotfiles-only mode
    if [[ "$INSTALL_MODE" == "dotfiles" && "${MODULE_DOTFILES_COMPAT:-false}" != "true" ]]; then
      exit 0
    fi
    run_module
  )
done

# ── Summary Banner ───────────────────────────────────────────────────────────
print_summary
