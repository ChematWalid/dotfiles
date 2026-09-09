# 🧩 Modular Installation Framework

This directory contains the modular and reusable installation engine for the dotfiles repository.

## 📂 Architecture

```
install/
├── lib/
│   ├── ui.sh               # Styling, colors, logging, and prompt helpers
│   ├── storage.sh          # Storage routing logic (single-drive vs multi-drive)
│   ├── link.sh             # Safe symlinking with automatic backups
│   └── summary.sh          # Post-installation summary and guidelines
├── modules/
│   ├── 01-system-update.sh
│   ├── 02-pacman-packages.sh
│   ├── 03-yay-aur.sh
│   ├── 04-aur-packages.sh
│   ├── 05-zsh-omz.sh
│   ├── 06-dotfiles.sh
│   ├── 07-desktop-tools.sh
│   ├── 08-telegram-forks.sh
│   ├── 09-app-hooks.sh
│   ├── 10-fonts.sh
│   ├── 11-wallpaper.sh
│   ├── 12-etc-system.sh
│   ├── 13-systemd-services.sh
│   └── 14-default-shell.sh
└── README.md
```

## 🛠️ How to Add a New Tool or Module

To add a new tool or installation phase, simply create a new script in `install/modules/` (e.g., `install/modules/15-my-tool.sh`):

```bash
#!/usr/bin/env bash
# ── install/modules/15-my-tool.sh ─────────────────────────────────────────────
MODULE_ID="my-tool"
MODULE_NAME="My Custom Tool"
MODULE_DESC="Description of what this tool installs or configures"
MODULE_DOTFILES_COMPAT=false  # Set to true if this should run in --dotfiles-only mode

run_module() {
  step "15 — My custom tool"
  if prompt_yn "Install My Custom Tool?" "y"; then
    info "Installing..."
    # Your installation logic here
    log "My Custom Tool installed"
  else
    warn "Skipped My Custom Tool"
  fi
}
```

The master script (`install.sh` / `installer.sh`) will **automatically discover** the new module! It will appear in:
- The `--list` output
- The interactive menu
- Individual module execution (`./install.sh -m my-tool`)

## 🚀 Execution Modes

| Command | Behavior |
|---|---|
| `./install.sh` / `./installer.sh` | Interactive mode selection menu |
| `./install.sh -y` / `--all` | Install all modules automatically (Accept all) |
| `./install.sh -i` / `--custom` | Interactive prompts for each module & tool |
| `./install.sh -d` / `--dotfiles-only` | Only symlink configs (Refuse package downloads) |
| `./install.sh -m <module>` | Run a single module (e.g. `-m fonts`, `-m desktop-tools`) |
| `./install.sh -l` / `--list` | List all available modules |
| `./install.sh -h` / `--help` | Show command usage |
