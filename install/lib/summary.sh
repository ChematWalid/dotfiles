#!/usr/bin/env bash
# ── install/lib/summary.sh ───────────────────────────────────────────────────
# Final summary banner and post-installation guidelines
# ─────────────────────────────────────────────────────────────────────────────

print_summary() {
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗"
  echo                    "║         ✅  Installation Complete!                   ║"
  echo -e                 "╚══════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "${BOLD}  Installed & Configured Tools:${RESET}"
  echo "  • Music Identifier   : shazam (CLI) & shazam -g (GUI / SongRec) [Mod+M / Mod+Shift+M]"
  echo "  • Scratchpad Terminal: Super+U / Alt+U (fast i3 toggle with debouncing)"
  echo "  • Workspace Autoname : autoname-workspaces (Rust dynamic icon engine)"
  echo "  • Desktop Audio Loop : desktop-music-daemon + mpris-live"
  echo "  • Window Helpers     : x11-grab-probe + libportal-remember-dir.so"
  echo ""
  echo -e "${BOLD}  Recommended Next Steps:${RESET}"
  echo "  ① Reboot system       : sudo reboot"
  echo "  ② GitHub CLI login    : gh auth login"
  echo "  ③ Password Vault      : rbw login"
  echo "  ④ Identify Song       : shazam  (plays through system speakers/headphones)"
  echo ""
  echo -e "${BOLD}  Documentation & Reference:${RESET}"
  echo "  • TOOLS_GUIDE.md      — full keybindings & cheatsheets"
  echo "  • ./install.sh --help — review script flags and modular execution options"
  echo ""
}
