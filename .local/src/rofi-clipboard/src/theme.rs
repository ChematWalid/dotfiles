//! Visual constants, dimensions, and Catppuccin Mocha palette for clipboard cards.

use image::Rgba;
use std::fs;
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::PathBuf;

pub const MAX_ITEMS: usize = 35;
pub const CARD_W: u32 = 750;
pub const CARD_H: u32 = 560;

pub fn cache_dir() -> anyhow::Result<PathBuf> {
    let runtime_dir = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .filter(|path| {
            let Ok(metadata) = fs::metadata(path) else {
                return false;
            };
            path.is_absolute() && metadata.is_dir() && metadata.mode() & 0o077 == 0
        });
    let base_dir = runtime_dir.or_else(|| {
        std::env::var_os("HOME")
            .map(PathBuf::from)
            .map(|home| home.join(".cache"))
    });
    let base_dir = base_dir.ok_or_else(|| anyhow::anyhow!("HOME is not set"))?;
    let path = base_dir.join("copyq_thumbs");

    fs::create_dir_all(&path)?;
    fs::set_permissions(&path, fs::Permissions::from_mode(0o700))?;

    Ok(path)
}

// Catppuccin Mocha Colors
pub const BG_COLOR: Rgba<u8> = Rgba([24, 24, 37, 255]); // Mantle
pub const HEADER_BG: Rgba<u8> = Rgba([30, 30, 46, 255]); // Base
pub const ACCENT_COLOR: Rgba<u8> = Rgba([203, 166, 247, 255]); // Mauve
pub const FG_COLOR: Rgba<u8> = Rgba([205, 214, 244, 255]); // Text
pub const MUTED_COLOR: Rgba<u8> = Rgba([108, 112, 134, 255]); // Overlay0
