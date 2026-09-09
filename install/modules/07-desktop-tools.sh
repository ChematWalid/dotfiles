#!/usr/bin/env bash
# ── install/modules/07-desktop-tools.sh ───────────────────────────────────────
MODULE_ID="desktop-tools"
MODULE_NAME="Desktop Tools & Daemons"
MODULE_DESC="Compile C/Rust tools (x11-grab-probe, portal-remember-dir, daemons) & setup SongRec"
MODULE_DOTFILES_COMPAT=false

run_module() {
  step "7 — Native C & Rust desktop tools"
  if prompt_yn "Compile and install native desktop tools (C helpers & Rust daemons)?" "y"; then
    mkdir -p "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/src"

    # ── 1. C Tools & Libraries ──────────────────────────────────────────────────
    if command -v gcc &>/dev/null; then
      # x11-grab-probe (X11 grab detector)
      if [[ -d "$HOME/.local/src/x11-grab-probe" ]]; then
        info "Compiling x11-grab-probe (C)..."
        gcc -O2 "$HOME/.local/src/x11-grab-probe/x11-grab-probe.c" -o "$HOME/.local/bin/x11-grab-probe" -lX11 2>/dev/null || true
        chmod +x "$HOME/.local/bin/x11-grab-probe" 2>/dev/null || true
        log "x11-grab-probe installed → ~/.local/bin/x11-grab-probe"
      fi

      # portal-remember-dir (GTK3 file chooser directory recall library)
      if [[ -d "$HOME/.local/src/portal-remember-dir" ]] && pkg-config --exists gtk+-3.0 2>/dev/null; then
        info "Compiling portal-remember-dir (C shared library)..."
        gcc -shared -fPIC -O2 "$HOME/.local/src/portal-remember-dir/portal-remember-dir.c" \
          -o "$HOME/.local/lib/libportal-remember-dir.so" $(pkg-config --cflags --libs gtk+-3.0) -ldl 2>/dev/null || true
        log "libportal-remember-dir.so installed → ~/.local/lib/libportal-remember-dir.so"
      fi

      # scratchpad_override (Fullscreen scratchpad helper library)
      if [[ -f "$DOTFILES_DIR/.local/lib/scratchpad_override.c" ]]; then
        cp "$DOTFILES_DIR/.local/lib/scratchpad_override.c" "$HOME/.local/lib/"
        gcc -shared -fPIC -O2 "$HOME/.local/lib/scratchpad_override.c" -o "$HOME/.local/lib/libscratchpad_override.so" -ldl -lX11 2>/dev/null || true
        log "libscratchpad_override.so installed → ~/.local/lib/libscratchpad_override.so"
      fi
    else
      warn "gcc not found — skipping C helpers compilation"
    fi

    # ── 2. Rust Desktop Daemons ─────────────────────────────────────────────────
    if command -v cargo &>/dev/null; then
      for pkg in desktop-music-daemon autoname-workspaces rofi-clipboard sync-antigravity mpris-live; do
        if [[ -d "$HOME/.local/src/$pkg" ]]; then
          info "Compiling $pkg (Rust)..."
          cargo build --release --manifest-path "$HOME/.local/src/$pkg/Cargo.toml" 2>/dev/null || true
          if [[ -f "$HOME/.local/src/$pkg/target/release/$pkg" ]]; then
            cp "$HOME/.local/src/$pkg/target/release/$pkg" "$HOME/.local/bin/$pkg"
            chmod +x "$HOME/.local/bin/$pkg"
            log "Compiled and installed $pkg → ~/.local/bin/$pkg"
          fi
        fi
      done
    else
      warn "cargo not found — skipping Rust daemons compilation"
    fi

    # ── 3. SongRec Audio Monitor Loopback Configuration ──────────────────────────
    if command -v pactl &>/dev/null && [[ -f "$HOME/.config/songrec/preferences.toml" ]]; then
      local default_sink
      default_sink="$(pactl get-default-sink 2>/dev/null || true)"
      if [[ -n "$default_sink" ]]; then
        local monitor_dev="${default_sink}.monitor"
        sed -i "s|^current_device_name = .*|current_device_name = \"$monitor_dev\"|" "$HOME/.config/songrec/preferences.toml" 2>/dev/null || true
        log "SongRec default audio monitor configured → $monitor_dev"
      fi
    fi
  else
    warn "Skipped native desktop tools compilation"
  fi
}
