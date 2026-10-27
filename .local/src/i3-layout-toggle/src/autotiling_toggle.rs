//! Smart autotiling toggle and Dunst feedback.

use std::io;
use std::process::Command;

pub fn run_autotiling_toggle() -> io::Result<()> {
    let is_active = Command::new("systemctl")
        .args(["--user", "is-active", "--quiet", "autotiling.service"])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);

    if is_active {
        let _ = Command::new("systemctl")
            .args(["--user", "stop", "autotiling.service"])
            .status();
        let _ = Command::new("dunstify")
            .args([
                "-u",
                "normal",
                "-t",
                "2000",
                "-h",
                "string:x-dunst-stack-tag:tiling",
                "🪟 Smart Autotiling",
                "Disabled (Manual i3 splitting)",
            ])
            .status();
    } else {
        let _ = Command::new("systemctl")
            .args(["--user", "start", "autotiling.service"])
            .status();
        let _ = Command::new("dunstify")
            .args([
                "-u",
                "normal",
                "-t",
                "2000",
                "-h",
                "string:x-dunst-stack-tag:tiling",
                "🪟 Smart Autotiling",
                "Enabled (Automatic aspect-ratio splits)",
            ])
            .status();
    }

    Ok(())
}
