use std::fs;
use std::path::{Path, PathBuf};

pub fn home_dir() -> PathBuf {
    match std::env::var_os("HOME") {
        Some(h) => PathBuf::from(h),
        None => PathBuf::from("/home/walid"),
    }
}

pub fn config_file_path() -> PathBuf {
    home_dir().join(".config").join("wallpaper-dir")
}

pub fn default_wallpaper_dir() -> PathBuf {
    home_dir().join("Pictures").join("walls-catppuccin-mocha")
}

pub fn runtime_dir() -> PathBuf {
    match std::env::var_os("XDG_RUNTIME_DIR") {
        Some(rt) => PathBuf::from(rt).join("dotfiles"),
        None => home_dir().join(".cache").join("dotfiles"),
    }
}

pub fn state_file_path() -> PathBuf {
    runtime_dir().join("wallpaper-current")
}

pub fn expand_path(raw: &str) -> PathBuf {
    let raw = raw.trim();
    if raw.is_empty() {
        return PathBuf::new();
    }

    let expanded = if raw == "~" {
        home_dir()
    } else if let Some(stripped) = raw.strip_prefix("~/") {
        home_dir().join(stripped)
    } else {
        PathBuf::from(raw)
    };

    if expanded.is_relative() {
        match std::env::current_dir() {
            Ok(cur) => cur.join(expanded),
            Err(_) => expanded,
        }
    } else {
        expanded
    }
}

pub fn get_configured_wallpaper_dir() -> PathBuf {
    let cfg_path = config_file_path();
    let default_dir = default_wallpaper_dir();

    if cfg_path.is_file() {
        if let Ok(content) = fs::read_to_string(&cfg_path) {
            let line = content.lines().next().unwrap_or("").trim();
            if !line.is_empty() {
                let candidate = expand_path(line);
                if candidate.is_dir() {
                    return candidate;
                } else {
                    eprintln!(
                        "wallpaper-manager: configured directory is unavailable: {}",
                        candidate.display()
                    );
                }
            }
        }
    }

    default_dir
}

pub fn set_configured_wallpaper_dir(dir: &Path) -> Result<(), std::io::Error> {
    let cfg_path = config_file_path();
    if let Some(parent) = cfg_path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&cfg_path, format!("{}\n", dir.display()))
}

pub fn get_current_wallpaper() -> Option<PathBuf> {
    let s_path = state_file_path();
    if s_path.is_file() {
        if let Ok(content) = fs::read_to_string(&s_path) {
            let line = content.lines().next().unwrap_or("").trim();
            if !line.is_empty() {
                return Some(PathBuf::from(line));
            }
        }
    }
    None
}

pub fn set_current_wallpaper(path: &Path) -> Result<(), std::io::Error> {
    let s_path = state_file_path();
    if let Some(parent) = s_path.parent() {
        fs::create_dir_all(parent)?;
    }
    fs::write(&s_path, format!("{}\n", path.display()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_expand_tilde() {
        let home = home_dir();
        assert_eq!(expand_path("~"), home);
        assert_eq!(expand_path("~/Pictures"), home.join("Pictures"));
        assert_eq!(expand_path("/tmp/foo"), PathBuf::from("/tmp/foo"));
    }

    #[test]
    fn test_paths_not_empty() {
        assert!(!config_file_path().as_os_str().is_empty());
        assert!(!default_wallpaper_dir().as_os_str().is_empty());
        assert!(!runtime_dir().as_os_str().is_empty());
        assert!(!state_file_path().as_os_str().is_empty());
    }
}
