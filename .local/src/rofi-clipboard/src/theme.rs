//! Visual constants, dimensions, and Catppuccin Mocha palette for clipboard cards.

use image::Rgba;

pub const CACHE_DIR: &str = "/tmp/copyq_thumbs";
pub const MAX_ITEMS: usize = 35;
pub const CARD_W: u32 = 750;
pub const CARD_H: u32 = 560;

// Catppuccin Mocha Colors
pub const BG_COLOR: Rgba<u8> = Rgba([24, 24, 37, 255]); // Mantle
pub const HEADER_BG: Rgba<u8> = Rgba([30, 30, 46, 255]); // Base
pub const ACCENT_COLOR: Rgba<u8> = Rgba([203, 166, 247, 255]); // Mauve
pub const FG_COLOR: Rgba<u8> = Rgba([205, 214, 244, 255]); // Text
pub const MUTED_COLOR: Rgba<u8> = Rgba([108, 112, 134, 255]); // Overlay0
