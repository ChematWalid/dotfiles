#!/usr/bin/env bash
# ── install/modules/07-desktop-tools.sh ───────────────────────────────────────
MODULE_ID="desktop-tools"
MODULE_NAME="Desktop Tools & Daemons"
MODULE_DESC="Compile C/Rust tools (x11-grab-probe, portal-remember-dir, daemons) & setup SongRec"
MODULE_DOTFILES_COMPAT=false

install_native_binary() {
  local source="$1" name="$2"
  local destination="$HOME/.local/bin/$name"
  local temporary="$destination.tmp.$$"

  if [[ -L "$destination" ]]; then
    local target
    target="$(readlink -f "$destination" 2>/dev/null || true)"
    if [[ "$target" == "$DOTFILES_DIR/.local/bin/$name" ]]; then
      unlink "$destination"
    else
      warn "Keeping existing custom symlink: $destination"
      return 1
    fi
  fi

  if install -m 755 "$source" "$temporary" && mv -f -- "$temporary" "$destination"; then
    return 0
  fi
  [[ ! -e "$temporary" ]] || unlink "$temporary"
  return 1
}

run_module() {
  step "7 — Native C & Rust desktop tools"
  if prompt_yn "Compile and install native desktop tools (C helpers & Rust daemons)?" "y"; then
    local -a gtk_flags=()
    local build_dir="$HOME/.cache/dotfiles-build"
    mkdir -p "$HOME/.local/bin" "$HOME/.local/lib" "$HOME/.local/src"
    mkdir -p "$build_dir"

    # ── 1. C Tools & Libraries ──────────────────────────────────────────────────
    if command -v gcc &>/dev/null; then
      # x11-grab-probe (X11 grab detector)
      if [[ -d "$DOTFILES_DIR/.local/src/x11-grab-probe" ]]; then
        info "Compiling x11-grab-probe (C)..."
        if gcc -O2 "$DOTFILES_DIR/.local/src/x11-grab-probe/x11-grab-probe.c" -o "$build_dir/x11-grab-probe" -lX11 && install_native_binary "$build_dir/x11-grab-probe" x11-grab-probe; then
          log "x11-grab-probe installed → ~/.local/bin/x11-grab-probe"
        else
          warn "Failed to compile x11-grab-probe"
        fi
      fi

      # portal-remember-dir (GTK3 file chooser directory recall library)
      if [[ -d "$DOTFILES_DIR/.local/src/portal-remember-dir" ]] && pkg-config --exists gtk+-3.0 2>/dev/null; then
        info "Compiling portal-remember-dir (C shared library)..."
        read -r -a gtk_flags <<< "$(pkg-config --cflags --libs gtk+-3.0)"
        if gcc -shared -fPIC -O2 "$DOTFILES_DIR/.local/src/portal-remember-dir/portal-remember-dir.c" \
          -o "$HOME/.local/lib/libportal-remember-dir.so" "${gtk_flags[@]}" -ldl
        then
          log "libportal-remember-dir.so installed → ~/.local/lib/libportal-remember-dir.so"
        else
          warn "Failed to compile portal-remember-dir"
        fi
      fi

      # scratchpad_override (Fullscreen scratchpad helper library)
      if [[ -f "$DOTFILES_DIR/.local/lib/scratchpad_override.c" ]]; then
        if gcc -shared -fPIC -O2 "$DOTFILES_DIR/.local/lib/scratchpad_override.c" -o "$HOME/.local/lib/libscratchpad_override.so" -ldl -lX11; then
          log "libscratchpad_override.so installed → ~/.local/lib/libscratchpad_override.so"
        else
          warn "Failed to compile scratchpad_override"
        fi
      fi

      # fdm-portal-fix (Qt6 portal file-dialog fix shared library)
      if [[ -d "$DOTFILES_DIR/.local/src/fdm-portal-fix" ]] && command -v g++ &>/dev/null; then
        info "Compiling fdm-portal-fix (C++ shared library)..."
        if g++ -fPIC -shared -O2 -Wall -Wextra -I/usr/include/qt6 -I/usr/include/qt6/QtCore \
          "$DOTFILES_DIR/.local/src/fdm-portal-fix/fdm-portal-fix.cpp" \
          -lQt6Core -o "$HOME/.local/lib/libfdm-portal-fix.so" -ldl 2>/dev/null; then
          log "libfdm-portal-fix.so installed → ~/.local/lib/libfdm-portal-fix.so"
        else
          warn "Failed to compile fdm-portal-fix"
        fi
      fi

      # lua-bidi (Conky Arabic BiDi shaping shared library)
      if [[ -d "$DOTFILES_DIR/.local/src/lua-bidi" ]] && command -v make &>/dev/null; then
        info "Compiling lua-bidi (C Lua module)..."
        if make -C "$DOTFILES_DIR/.local/src/lua-bidi" all && \
           make -C "$DOTFILES_DIR/.local/src/lua-bidi" install DESTDIR="$HOME/.config/conky"; then
          log "lua-bidi installed → ~/.config/conky/bidi.so"
        else
          warn "Failed to compile lua-bidi"
        fi
      fi

      # xkb-group-toggle (X11 layout toggler)
      if [[ -d "$DOTFILES_DIR/.local/src/xkb-group-toggle" ]] && command -v make &>/dev/null; then
        info "Compiling xkb-group-toggle (C++)..."
        if make -C "$DOTFILES_DIR/.local/src/xkb-group-toggle" all && \
           install_native_binary "$DOTFILES_DIR/.local/src/xkb-group-toggle/xkb-group-toggle" xkb-group-toggle; then
          log "xkb-group-toggle installed → ~/.local/bin/xkb-group-toggle"
        else
          warn "Failed to compile xkb-group-toggle"
        fi
      fi

      # polybar-datetime (Polybar datetime & prayer time helper)
      if [[ -d "$DOTFILES_DIR/.local/src/polybar-datetime" ]] && command -v cmake &>/dev/null && command -v g++ &>/dev/null; then
        info "Compiling polybar-datetime (CMake C++)..."
        local dt_build="$build_dir/polybar-datetime"
        mkdir -p "$dt_build"
        if cmake -B "$dt_build" -S "$DOTFILES_DIR/.local/src/polybar-datetime" -DCMAKE_BUILD_TYPE=Release && \
           cmake --build "$dt_build" && \
           install_native_binary "$dt_build/polybar-datetime" polybar-datetime; then
          log "polybar-datetime installed → ~/.local/bin/polybar-datetime"
        else
          warn "Failed to compile polybar-datetime"
        fi
      fi
    else
      warn "gcc not found — skipping C helpers compilation"
    fi

    # ── 2. Rust Desktop Daemons ─────────────────────────────────────────────────
    if command -v cargo &>/dev/null; then
      for pkg in desktop-music-daemon autoname-workspaces rofi-clipboard mpris-live i3-layout-toggle wallpaper-manager; do
        if [[ -d "$DOTFILES_DIR/.local/src/$pkg" ]]; then
          info "Compiling $pkg (Rust)..."
          local manifest="$DOTFILES_DIR/.local/src/$pkg/Cargo.toml"
          if cargo build --release --manifest-path "$manifest"; then
            if [[ ! -x "$DOTFILES_DIR/.local/src/$pkg/target/release/$pkg" ]]; then
              warn "Build of $pkg succeeded but its executable was not produced"
              continue
            fi
            if ! install_native_binary "$DOTFILES_DIR/.local/src/$pkg/target/release/$pkg" "$pkg"; then
              warn "Failed to install $pkg"
              continue
            fi
            log "Compiled and installed $pkg → ~/.local/bin/$pkg"
          else
            warn "Failed to compile $pkg"
          fi
        fi
      done
    else
      warn "cargo not found — skipping Rust daemons compilation"
    fi

    # ── 3. Polybar Native Helpers ───────────────────────────────────────────────
    if command -v make &>/dev/null && command -v g++ &>/dev/null && [[ -f "$DOTFILES_DIR/.config/polybar/Makefile" ]]; then
      info "Compiling Polybar native helpers (network-eth-live, network-status-live, tray-autohide, prayer-live)..."
      if make -C "$DOTFILES_DIR/.config/polybar" all; then
        log "Polybar native helpers compiled"
      else
        warn "Failed to compile some Polybar native helpers"
      fi
    fi

    # ── 4. Shared C++ Headers ───────────────────────────────────────────────────
    if [[ -d "$DOTFILES_DIR/.local/include" ]]; then
      mkdir -p "$HOME/.local/include"
      cp -ru "$DOTFILES_DIR/.local/include/." "$HOME/.local/include/" 2>/dev/null || true
      log "Centralized C++ headers installed → ~/.local/include/dotfiles"
    fi

    # ── 5. SongRec Audio Monitor Loopback Configuration ──────────────────────────
    if command -v pactl &>/dev/null && [[ -f "$HOME/.config/songrec/preferences.toml" ]]; then
      local default_sink
      default_sink="$(pactl get-default-sink 2>/dev/null || true)"
      if [[ -n "$default_sink" ]]; then
        local monitor_dev="${default_sink}.monitor"
        sed -i --follow-symlinks "s|^current_device_name = .*|current_device_name = \"$monitor_dev\"|" "$HOME/.config/songrec/preferences.toml" 2>/dev/null || true
        log "SongRec default audio monitor configured → $monitor_dev"
      fi
    fi
  else
    warn "Skipped native desktop tools compilation"
  fi
}
