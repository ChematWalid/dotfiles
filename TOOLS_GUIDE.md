# 🚀 Arch Linux Catppuccin Ecosystem — Master Tool Manual & Cheatsheet

Welcome to your complete reference manual! Every tool, custom script, keybinding, and workflow on your system is documented below with practical examples.

---

## 📑 Table of Contents
1. [🪟 Desktop & Window Management (i3 / Rofi / Conky / Dunst)](#1--desktop--window-management)
2. [🐚 Shell, Terminal & Productivity (Zsh / Atuin / Navi / Tmux)](#2--shell-terminal--productivity)
3. [📁 File Navigation & Disk Management (Lf / Yazi / Dust / Ouch)](#3--file-navigation--disk-management)
4. [🔐 Passwords & Security (Vaultwarden / Bitwarden / Rofi-RBW)](#4--passwords--security)
5. [🐳 Docker & Development Runtimes (Portainer / Lazydocker / Mise)](#5--docker--development-runtimes)
6. [🐙 Git & GitHub Workflow (Gitui / Gh-Dash / Delta)](#6--git--github-workflow)
7. [🌐 Networking & Web Tools (Cloudflare Tunnels / Netscanner / XH)](#7--networking--web-tools)
8. [📊 Data Wrangling & Code Search (Visidata / Dasel / Ast-Grep / Sd)](#8--data-wrangling--code-search)
9. [⏱️ Task, Time & Calendar Management (Taskwarrior / Timewarrior / Khal)](#9--task-time--calendar-management)
10. [🎵 Media, Audio & Visuals (MPD / Ncmpcpp / Cava / Playerctl)](#10--media-audio--visuals)
11. [🤖 AI & Companion CLI (Google Antigravity)](#11--ai--companion-cli)
12. [🎨 ASCII Art & Terminal Aesthetics](#12--ascii-art--terminal-aesthetics)

---

## 1. 🪟 Desktop & Window Management

### Core Shortcuts (Primary: `Alt` / `Mod1`, Secondary: `Win` / `Mod4`)

| Shortcut | Action | Description |
|---|---|---|
| **`Alt + Return`** / `Win + Return` | Open Terminal | Opens Kitty (or Alacritty with `Win+Return`) |
| **`Alt + Q`** / `Alt + Shift + Q` | Kill Window | Closes the focused application window |
| **`Alt + D`** | Rofi App Launcher | Search and launch any desktop application |
| **`Win + L`** / `Alt + Ctrl + L` | Lock Screen | Aesthetic Gaussian-blurred Catppuccin lockscreen |
| **`Win + P`** / `Alt + P` | Password Auto-Typer | Rofi Vaultwarden credentials picker |
| **`Alt + V`** / `Win + V` | Clipboard Manager | CopyQ clipboard history floating window |
| **`Alt + U`** / `Win + U` | Dropdown Scratchpad | Toggle floating quick-terminal from anywhere |
| **`Alt + M`** / `Win + M` | Shazam Song Identifier | Identify playing music from system audio |
| **`Alt + Shift + M`** / `Win + Shift + M` | SongRec GUI | Open full graphical Shazam / SongRec app |
| **`Alt + =`** / `Win + C` | Calculator | Instant Rofi mathematical calculator |
| **`Alt + Shift + W`** / `Win + W` | Web Search | Fast Google/GitHub search directly from Rofi |
| **`Alt + Shift + T`** / `Win + Shift + T` | Toggle Autotiling | Switch between automatic aspect-ratio tiling and manual splits |
| **`Alt + 1..10`** / `Win + 1..10` | Switch Workspace | Jump to numbered workspace |
| **`Alt + Shift + 1..10`** | Move Container | Move focused window to workspace |

---

### Media & Hardware Function Keys (No `Fn` Key Required)

| Shortcut | Hardware Key | Action |
|---|---|---|
| **`Win + F1`** / `Alt + F1` | `XF86AudioMute` | Mute / Unmute Audio (Dunst OSD popup) |
| **`Win + F2`** / `Alt + F2` | `XF86AudioLowerVolume`| Volume Down (-5%) |
| **`Win + F3`** / `Alt + F3` | `XF86AudioRaiseVolume`| Volume Up (+5%) |
| **`Win + F5`** / `Alt + F5` | `XF86MonBrightnessDown`| Screen Brightness Down (-10%) |
| **`Win + F6`** / `Alt + F6` | `XF86MonBrightnessUp` | Screen Brightness Up (+10%) |
| **`Win + F7`** / `Alt + F7` | `XF86AudioPrev` | Previous Music Track |
| **`Win + F8`** / `Alt + F8` | `XF86AudioPlay` | Play / Pause Music Track |
| **`Win + F9`** / `Alt + F9` | `XF86AudioNext` | Next Music Track |

---

## 2. 🐚 Shell, Terminal & Productivity

### Modern Shell Tools

- **`atuin` (Fuzzy Shell History)**:
  - **`Ctrl + R`**: Interactive search across your full command history with execution duration, exit codes, and timestamps.
  - `atuin stats`: Show your most frequently used commands and shell statistics.
- **`thefuck` (Instant Typo Correction)**:
  - Press **`ESC ESC`** (or type `fuck`) after an error command to automatically detect and run the corrected command.
- **`navi` (Interactive Terminal Cheatsheets)**:
  - Press **`Ctrl + G`**: Opens interactive cheatsheet menu. Select any command and fill in variables dynamically!
  - `navi`: Search all cheatsheets.
- **`zoxide` (Smarter `cd` with Frequencies)**:
  - `z project`: Jump straight to `~/Coding/project` without typing full paths.
  - `zi`: Interactive fuzzy directory picker with FZF.
- **`eza` (Modern `ls` with Icons & Git Status)**:
  - `ls`: Colorized listing with icons.
  - `ll`: Long format with file permissions, sizes, and Git status.
  - `tree`: Hierarchical directory tree view.
- **`bat` (Syntax-Highlighted `cat`)**:
  - `bat <file>`: Reads file with line numbers, Git modifications, and Catppuccin theme.

---

### `tmux` (Terminal Multiplexer)

**Prefix Key**: **`Ctrl + a`** (or `Ctrl + b`)

| Command / Shortcut | Description |
|---|---|
| **`tma`** | Attach to main session or create a new one |
| **`tml`** | List all running tmux sessions |
| **`tmk <name>`** | Kill a specific session |
| **`Ctrl+a \|`** (or `\`) | Split pane **vertically** in current directory |
| **`Ctrl+a -`** (or `_`) | Split pane **horizontally** in current directory |
| **`Ctrl+a h / j / k / l`** | Move focus between split panes (or click with mouse) |
| **`Ctrl+a z`** | **Zoom / Unzoom** active pane to fullscreen |
| **`Ctrl+a c`** | Create new window tab |
| **`Ctrl+a 1..9`** | Switch to window tab 1 to 9 |
| **`Ctrl+a d`** | Detach session (leaves all processes running in background) |
| **`Ctrl+a r`** | Reload tmux configuration |

---

## 3. 📁 File Navigation & Disk Management

- **`lf` (Terminal File Manager with Rich Previews)**:
  - Launch: `lf`
  - Features: Vim key navigation (`h,j,k,l`), previewing code (`bat`), video thumbnails (`ffmpegthumbnailer`), PDF first-page rendering (`poppler`), and archive listing (`ouch`).
- **`yazi` & `superfile` (`spf`)**:
  - Blazing-fast async terminal file managers with visual tabs and dual-pane views.
- **`broot` (`br`)**:
  - Interactive tree navigator that calculates disk weights and lets you navigate complex directory hierarchies effortlessly.
- **`dust` (Visual Disk Usage Analyzer)**:
  - `dust`: Visual graphical tree showing which directories consume the most disk space.
  - `dust /mnt/drive2`: Inspect 1TB HDD consumption.
- **`ouch` (Painless Archive Compression & Extraction)**:
  - `ouch decompress archive.tar.gz` (or `.zip`, `.7z`, `.tar.zst`): Automatically detects and extracts any archive format.
  - `ouch compress folder/ archive.zip`: Compresses files/folders into any target format.
  - `ouch list archive.tar.gz`: View archive contents without extracting.
- **`trash-cli` (Safe Deletions without Permanent Loss)**:
  - `tp <file>`: Move file/folder to trash (`trash-put`).
  - `tl`: List all items currently in trash (`trash-list`).
  - `trs`: Interactively choose items to restore back to their original location (`trash-restore`).
  - `te`: Empty the trash (`trash-empty`).
- **`plocate` (Sub-Millisecond File Search)**:
  - `plocate <filename>`: Instantly find any file across your entire storage drives.
  - `sudo updatedb`: Refresh file index database.
- **`fselect` (SQL Queries for Filesystem)**:
  - `fselect "name, size FROM /home WHERE size > 100mb ORDER BY size DESC"`

---

## 4. 🔐 Passwords & Security

- **Self-Hosted Vaultwarden (Docker + HTTPS Caddy)**:
  - Dedicated Port: **`https://localhost:8222`** (or `https://192.168.100.47:8222` on local LAN).
  - Open Web Vault: `vw` (or run `vaultwarden`).
  - Stored permanently on HDD: `/mnt/drive2/docker-data/vaultwarden/`.
- **Rofi Password Auto-Typer (`rofi-rbw`)**:
  - Press **`Win + P`** (or `Alt + P`) anywhere.
  - Select your credential ➔ automatically types your username and password into any browser or desktop login screen!
- **Bitwarden CLI (`bw`) & Auto-Persistence**:
  - `bw-unlock`: Unlocks your vault once and automatically persists the session across **all terminal tabs** via `~/.cache/.bw_session`.
  - `genpass`: Generate a 24-character secure password (letters, numbers, symbols).
  - `genphrase`: Generate a secure 4-word hyphenated passphrase (e.g. `correct-horse-battery-staple`).
  - `bw list items`: List stored vault items in terminal.

---

## 5. 🐳 Docker & Development Runtimes

- **Docker Daemon Storage**:
  - Permanently routed to HDD: `/mnt/drive2/docker/`.
  - Service automatically active on system boot.
- **`lazydocker` (`ld`)**:
  - Interactive terminal dashboard to view running containers, CPU/memory stats, logs, restart containers, and clean unused images.
- **`ctop` (`dtop`)**:
  - Real-time container top monitor showing live container network I/O, memory, and CPU percentages.
- **Portainer CE Web GUI (`dgui`)**:
  - Launch: `dgui` (or `docker-gui`).
  - Opens Portainer container management dashboard at **`http://localhost:9000`**.
- **`mise` (Polyglot Runtime & Tool Manager)**:
  - Stored on HDD at `/mnt/drive2/.mise/`.
  - `mise use -g node@22`: Switch global Node.js version.
  - `mise use -g python@3.12`: Switch global Python version.
  - `mise use -g go@latest`: Install and use Go.
  - `mise list`: View all installed SDKs and runtimes.
- **`hdd-route` (Automated HDD App Storage Migration)**:
  - `hdd-route status`: View HDD cache symlinks and free space.
  - `hdd-route steam`: Migrate Steam library to HDD.
  - `hdd-route vscode`: Migrate VSCode extensions to HDD.

---

## 6. 🐙 Git & GitHub Workflow

- **`gh-dash` (`ghd`)**:
  - Interactive terminal dashboard styled in **Catppuccin Mocha**.
  - Displays Pull Requests, assigned Issues, notifications, and CI/CD workflow status.
- **`gitui` (`gg`)**:
  - Ultra-fast 0ms latency Rust TUI for staging files, writing commits, branching, and pushing.
- **`difftastic` (AST Structural Code Diffs)**:
  - `dlog`: View Git commit history with syntax-aware semantic diffs.
  - `dshow <commit>`: Show changes in a specific commit.
- **Git Shortcuts**:
  - `git undo`: Safely undo last commit while keeping your edited files in working state.
  - `git graph`: Visual ASCII branch and merge tree.
  - `git sync`: One-command pull with rebase and push.
  - `git amend`: Add staged changes to previous commit without changing message.
  - `git st`: Clean compact status (`git status -s`).
  - `git cob <name>`: Create and checkout new branch.
  - `git last`: Show full diff and files changed in the most recent commit.

---

## 7. 🌐 Networking & Web Tools

- **`share-port` / `tunnel` (Cloudflare Public Tunnels)**:
  - `tunnel 8222`: Expose your self-hosted Vaultwarden to the internet with an instant secure HTTPS link.
  - `share 3000`: Share a local web application or dev server with anyone remotely.
  - Press `Ctrl + C` to instantly shut down the tunnel.
- **`xh` (Friendly & Fast HTTP Tool)**:
  - `xh get https://httpbin.org/json`: Send GET request with formatted JSON output.
  - `xh post https://httpbin.org/post name=Walid role=admin`: Send JSON POST data easily.
- **`dog` (Modern DNS Client with Colors)**:
  - `dog google.com`: Query A records.
  - `dog google.com MX @1.1.1.1`: Query MX records using Cloudflare DNS.
- **`gping` (Visual Ping Graph)**:
  - `gping 1.1.1.1 8.8.8.8`: Real-time interactive latency graph comparing two hosts.
- **`netscanner`**:
  - Interactive TUI scanner to discover all devices, IP addresses, and open ports on your local WiFi/LAN.
- **`trippy` (`trip` / `traceroute`)**:
  - `trip google.com`: Interactive network traceroute analyzing ping and packet loss at every network hop.
- **`bandwhich`**:
  - `sudo bandwhich`: Live network utilization monitor showing which processes are consuming bandwidth.

---

## 8. 📊 Data Wrangling & Code Search

- **`visidata` (`vd`)**:
  - `vd data.csv` (or `.json`, `.sqlite`, `.xlsx`): Interactive multi-million row spreadsheet terminal explorer. Perform filtering, frequency analysis, pivoting, and charting instantly.
- **`dasel` (Data Structure Query & Conversion)**:
  - `dasel -f config.json '.server.port'`: Query JSON values.
  - `dasel -f data.yaml -p yaml -t json`: Convert YAML directly to JSON.
- **`ast-grep` (`sg`) (Code Structure Search)**:
  - `sg 'console.log($$$A)' --lang js`: Search codebase using JavaScript AST patterns rather than plain text regex.
- **`sd` (Intuitive & Fast `sed`)**:
  - `sd 'old_text' 'new_text' file.txt`: Replace text directly in files without cryptic sed syntax.
- **`choose` (Human-Friendly `cut` / `awk`)**:
  - `ps aux | choose 0 1 10`: Extract columns 0, 1, and 10 with 0-indexed slicing.
- **`gron` (Make JSON Greppable)**:
  - `gron api.json | grep "username" | gron -u`: Unflatten JSON into easy greppable assignment lines and turn back into JSON.
- **`xsv` & `miller` (`mlr`)**:
  - High-performance slice, dice, and statistics tools for massive CSV/TSV datasets.
- **`grex` (Regex Generator)**:
  - `grex "2026-08-21" "2026-12-31"`: Automatically outputs a minimal regular expression matching the provided examples.
- **`hyperfine` (`bench`)**:
  - `bench 'fd pattern' 'find . -name pattern'`: Statistical benchmarking comparing command execution speeds.
- **`translate-shell` (Multi-Language CLI Translator)**:
  - `tr en:fr "hello world"`: Translate English to French.
  - `trfr "bonjour"`: Translate to French.
  - `tren "merci"`: Translate to English.
  - `trar "welcome"`: Translate to Arabic.

---

## 9. ⏱️ Task, Time & Calendar Management

- **`taskwarrior` (`t`)**:
  - `t add "Finish project" priority:H due:tomorrow`: Add a new task with priority and deadline.
  - `t`: List active pending tasks.
  - `t 1 done`: Mark task #1 as completed.
- **`timewarrior` (`tw`)**:
  - `tw start "Coding backend"`: Start tracking time on a task.
  - `tw stop`: Stop active timer.
  - `tw summary`: View detailed breakdown of hours worked today/this week.
- **`calcurse` (`cal`)**:
  - Interactive terminal calendar and daily organizer.
- **`khal` (`kc` / `agenda`)**:
  - `agenda`: Show your upcoming scheduled events and calendar appointments.
  - `khal new 25/08 14:00 15:00 "Team Meeting"`: Add a new calendar event.

---

## 10. 🎵 Media, Audio & Visuals

- **`shazam` / `whatsong` (Music Recognition from System Audio)**:
  - **`shazam`** (or `Alt + M` / `Win + M`): Instantly recognizes music currently playing on your speakers/headphones (via PipeWire loopback) with album cover art, Dunst notification, terminal card, and clipboard copy.
  - **`shazam -g`** (or `Alt + Shift + M` / `Win + Shift + M`): Launches the full graphical SongRec GTK GUI with song recognition history, Shazam database search, and YouTube links.
  - **`shazam -c`**: Continuous listening mode in terminal.
  - **`shazam -f <file>`**: Identify music from any local audio or video file.
- **Desktop Real-Time Music Widget (Conky)**:
  - Automatically displays the live track and artist right beneath the centered desktop clock in Catppuccin Green & White with zero lag via event-driven DBus!
- **Polybar Live Music Pill**:
  - Centered bottom bar player with interactive Play/Pause (`󰏥`/`󰐌`), Next (`󰒭`), Prev (`󰒮`), and smooth mouse-hover marquee scrolling!
- **`ncmpcpp` (`music`)**:
  - Visual terminal music player connected to MPD daemon.
- **`cava` (`vis`)**:
  - Real-time responsive Catppuccin audio spectrum visualizer.
- **`playerctl`**:
  - `playerctl play-pause`: Toggle music.
  - `playerctl next` / `previous`: Skip tracks.

---

## 11. 🤖 AI & Companion CLI

- **Google Antigravity CLI (`agy`)**:
  - `agy`: Launch interactive Antigravity agentic coding session in the current project directory.
  - `agy-last` (or `agy -c`): **Resume your most recent conversation** directly in the terminal!
  - `agy-ask "how to deploy this compose file"` (or `agy -p "..."`): Instant one-off AI question without entering interactive mode.
  - `agy models`: List all available AI model backends.
  - `agy agents`: List active agent capabilities.

---

## 12. 🎨 ASCII Art & Terminal Aesthetics

- **`cmatrix`**: Classic Green/Catppuccin Matrix digital rain.
- **`cbonsai`**: Live growing Bonsai tree generator.
- **`asciiquarium`**: Animated terminal aquarium with fish, sharks, and water animations.
- **`asciinema`**: Record your terminal sessions into shareable SVG/web animations (`asciinema rec demo.cast`).
- **`pipes.sh`**: Animated 3D colorful plumbing pipes.
- **`figlet` & `toilet`**: Giant banner ASCII text generator (`figlet "Arch Linux" | lolcat`).
- **`boxes`**: Wrap comments and text in ascii borders (`echo "Important Notice" | boxes -d cat`).
- **`ascii-image-converter` / `jp2a`**: Convert any image file into ASCII art directly in the terminal!

---

*Generated for Walid • Arch Linux Catppuccin Edition • Tracked in [dotfiles](https://github.com/ChematWalid/dotfiles)*
