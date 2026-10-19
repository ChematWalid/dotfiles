//! Configuration paths and glyphs for desktop-music-daemon.

use anyhow::{Context, Result};
use std::path::PathBuf;

pub fn output_paths() -> Result<(PathBuf, PathBuf)> {
    let runtime_dir = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .filter(|path| path.is_absolute())
        .or_else(|| {
            std::env::var_os("HOME")
                .map(PathBuf::from)
                .filter(|path| path.is_absolute())
                .map(|home| home.join(".cache"))
        })
        .context("XDG_RUNTIME_DIR and absolute HOME are both unavailable")?;
    let output = runtime_dir.join("conky-music.txt");
    let temporary = runtime_dir.join(format!("conky-music.txt.{}.tmp", std::process::id()));
    Ok((output, temporary))
}

// Nerd Font Glyphs (matching Polybar mpris-live)
pub const ICON_PLAY: &str = "\u{f03e4}"; // 󰏤 Pause bars || (when playing)
pub const ICON_PAUSE: &str = "\u{f040a}"; // 󰐊 Play triangle ▶ (when paused)
