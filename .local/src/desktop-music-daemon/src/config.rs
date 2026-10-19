//! Configuration paths and glyphs for desktop-music-daemon.

use std::path::PathBuf;

pub fn output_paths() -> (PathBuf, PathBuf) {
    let runtime_dir = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .filter(|path| path.is_absolute())
        .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".cache")))
        .expect("XDG_RUNTIME_DIR or HOME must be set");
    let output = runtime_dir.join("conky-music.txt");
    let temporary = runtime_dir.join(format!("conky-music.txt.{}.tmp", std::process::id()));
    (output, temporary)
}

// Nerd Font Glyphs (matching Polybar mpris-live)
pub const ICON_PLAY: &str = "\u{f03e4}"; // 󰏤 Pause bars || (when playing)
pub const ICON_PAUSE: &str = "\u{f040a}"; // 󰐊 Play triangle ▶ (when paused)
