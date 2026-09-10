//! Configuration constants and palette for mpris-live.

pub const MAX_CHARS: usize = 18;
pub const SCROLL_MS: u64 = 180;
pub const SEPARATOR: &str = "   •   ";

pub const CONKY_FILE: &str = "/tmp/conky-music.txt";
pub const CONKY_TMP: &str = "/tmp/conky-music.txt.tmp";
pub const PID_FILE: &str = "/tmp/.polybar-mpris-live.pid";

// Polybar bottom bar hover coordinate boundaries (768p screen)
pub const HOVER_Y_MIN: i16 = 720;
pub const HOVER_X_MIN: i16 = 400;
pub const HOVER_X_MAX: i16 = 920;

// Nerd Font Glyphs
pub const ICON_PAUSE_BTN: &str = "\u{f03e5}"; // 󰏥 pause circle
pub const ICON_PLAY_BTN: &str = "\u{f040c}"; // 󰐌 play circle
pub const ICON_PREV: &str = "\u{f04ae}"; // 󰒮 previous
pub const ICON_NEXT: &str = "\u{f04ad}"; // 󰒭 next
pub const ICON_NOTE: &str = "\u{f0386}"; // 󰎆 musical note
pub const ICON_CONKY_PLAY: &str = "\u{f03e4}"; // 󰏤 pause bars || (when playing)
pub const ICON_CONKY_PAUSE: &str = "\u{f040a}"; // 󰐊 play triangle ▶ (when paused)

// Catppuccin Mocha Colors
pub const COLOR_GREEN: &str = "#a6e3a1";
pub const COLOR_YELLOW: &str = "#f9e2af";
pub const COLOR_BLUE: &str = "#89b4fa";
pub const COLOR_PINK: &str = "#f5c2e7";
pub const COLOR_TEXT: &str = "#cdd6f4";
