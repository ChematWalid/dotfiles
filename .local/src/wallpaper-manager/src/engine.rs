use crate::config;
use crate::scanner;
use std::fs::File;
use std::io::Read;
use std::path::{Path, PathBuf};
use std::process::Command;

pub fn get_random_u64() -> u64 {
    let mut buf = [0u8; 8];
    if let Ok(mut f) = File::open("/dev/urandom") {
        if f.read_exact(&mut buf).is_ok() {
            return u64::from_ne_bytes(buf);
        }
    }

    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    (nanos as u64) ^ (std::process::id() as u64)
}

pub fn random_index(limit: usize) -> usize {
    if limit <= 1 {
        return 0;
    }
    (get_random_u64() % (limit as u64)) as usize
}

pub fn pick_next_wallpaper(walls: &[PathBuf], current: Option<&Path>) -> Option<PathBuf> {
    if walls.is_empty() {
        return None;
    }
    if walls.len() == 1 {
        return Some(walls[0].clone());
    }

    let current_index = current.and_then(|cur| walls.iter().position(|w| w == cur));

    match current_index {
        Some(idx) => {
            let choice_count = walls.len() - 1;
            let mut selected = random_index(choice_count);
            if selected >= idx {
                selected += 1;
            }
            Some(walls[selected].clone())
        }
        None => {
            let selected = random_index(walls.len());
            Some(walls[selected].clone())
        }
    }
}

pub fn apply_wallpaper(path: &Path) -> Result<(), String> {
    let status = Command::new("feh")
        .arg("--bg-fill")
        .arg(path)
        .status()
        .map_err(|e| format!("Failed to execute feh: {}", e))?;

    if !status.success() {
        return Err(format!("feh exited with status: {}", status));
    }

    if let Err(e) = config::set_current_wallpaper(path) {
        eprintln!(
            "wallpaper-manager: warning: failed to write state file: {}",
            e
        );
    }

    Ok(())
}

pub fn notify_rotation_daemon() {
    let is_active = Command::new("systemctl")
        .args(["--user", "is-active", "--quiet", "wallpaper-rotate.service"])
        .status()
        .map(|s| s.success())
        .unwrap_or(false);

    if is_active {
        let _ = Command::new("systemctl")
            .args([
                "--user",
                "kill",
                "--signal=USR1",
                "--kill-whom=main",
                "wallpaper-rotate.service",
            ])
            .status();
    } else {
        let _ = Command::new("systemctl")
            .args(["--user", "reset-failed", "wallpaper-rotate.service"])
            .status();
        let _ = Command::new("systemctl")
            .args(["--user", "start", "wallpaper-rotate.service"])
            .status();
    }
}

pub fn switch_next(notify: bool) -> Result<PathBuf, String> {
    let wall_dir = config::get_configured_wallpaper_dir();
    let walls = scanner::scan_wallpapers(&wall_dir, 3);

    if walls.is_empty() {
        return Err(format!(
            "No wallpapers found in {}",
            wall_dir.display()
        ));
    }

    let current = config::get_current_wallpaper();
    let picked = pick_next_wallpaper(&walls, current.as_deref())
        .ok_or_else(|| "Failed to pick next wallpaper".to_string())?;

    apply_wallpaper(&picked)?;

    if notify {
        notify_rotation_daemon();
    }

    Ok(picked)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_pick_empty() {
        assert_eq!(pick_next_wallpaper(&[], None), None);
    }

    #[test]
    fn test_pick_single() {
        let walls = vec![PathBuf::from("/a.png")];
        assert_eq!(
            pick_next_wallpaper(&walls, Some(Path::new("/a.png"))),
            Some(PathBuf::from("/a.png"))
        );
    }

    #[test]
    fn test_pick_multiple_avoids_current() {
        let walls = vec![
            PathBuf::from("/a.png"),
            PathBuf::from("/b.png"),
        ];

        // When current is /a.png, must always pick /b.png
        for _ in 0..20 {
            let picked = pick_next_wallpaper(&walls, Some(Path::new("/a.png")));
            assert_eq!(picked, Some(PathBuf::from("/b.png")));
        }

        // When current is /b.png, must always pick /a.png
        for _ in 0..20 {
            let picked = pick_next_wallpaper(&walls, Some(Path::new("/b.png")));
            assert_eq!(picked, Some(PathBuf::from("/a.png")));
        }
    }
}
