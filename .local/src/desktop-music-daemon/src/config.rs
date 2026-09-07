//! Configuration constants and paths for desktop-music-daemon.

pub const OUTPUT_FILE: &str = "/tmp/conky-music.txt";
pub const TMP_FILE: &str = "/tmp/conky-music.txt.tmp";
pub const PID_FILE: &str = "/tmp/.desktop-music-daemon.pid";

// Nerd Font Glyphs (matching Polybar mpris-live)
pub const ICON_PLAY: &str = "\u{f03e5}"; // 󰏥 Pause circle (when playing)
pub const ICON_PAUSE: &str = "\u{f040c}"; // 󰐌 Play circle (when paused)
