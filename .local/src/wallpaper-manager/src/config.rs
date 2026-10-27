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

pub fn state_dir() -> PathBuf {
    match std::env::var_os("XDG_STATE_HOME") {
        Some(s) => PathBuf::from(s).join("dotfiles"),
        None => home_dir().join(".local").join("state").join("dotfiles"),
    }
}

pub fn history_file_path() -> PathBuf {
    let state_file = state_dir().join("wallpaper-history");
    if !state_file.is_file() {
        let rt_file = runtime_dir().join("wallpaper-history");
        if rt_file.is_file() {
            if let Some(parent) = state_file.parent() {
                let _ = fs::create_dir_all(parent);
            }
            let _ = fs::copy(&rt_file, &state_file);
        }
    }
    state_file
}

pub fn record_history_with_current(path: &Path, hist_path: &Path, current: Option<&Path>) {
    let mut history: Vec<String> = if hist_path.is_file() {
        fs::read_to_string(hist_path)
            .map(|c| {
                c.lines()
                    .map(|s| s.trim().to_string())
                    .filter(|s| !s.is_empty())
                    .collect()
            })
            .unwrap_or_default()
    } else {
        Vec::new()
    };

    let path_str = path.display().to_string();

    // If history is empty, record existing active wallpaper first
    if history.is_empty() {
        if let Some(cur) = current {
            let cur_str = cur.display().to_string();
            if cur_str != path_str {
                history.push(cur_str);
            }
        }
    }

    if history.last().map(|s| s.as_str()) != Some(&path_str) {
        history.push(path_str);
        if history.len() > 50 {
            history.drain(0..history.len() - 50);
        }
        if let Some(parent) = hist_path.parent() {
            let _ = fs::create_dir_all(parent);
        }
        let _ = fs::write(hist_path, history.join("\n") + "\n");
    }
}

pub fn record_history_to(path: &Path, hist_path: &Path) {
    record_history_with_current(path, hist_path, get_current_wallpaper().as_deref());
}

pub fn record_history(path: &Path) {
    let hist_path = history_file_path();
    record_history_to(path, &hist_path);
}

pub fn pop_previous_wallpaper_from(hist_path: &Path) -> Option<PathBuf> {
    if !hist_path.is_file() {
        return None;
    }
    let mut history: Vec<String> = fs::read_to_string(hist_path)
        .map(|c| {
            c.lines()
                .map(|s| s.trim().to_string())
                .filter(|s| !s.is_empty())
                .collect()
        })
        .ok()?;

    if history.len() < 2 {
        return None;
    }

    // Pop the currently displayed wallpaper
    let current = history.pop();

    // Find the nearest previous wallpaper that still exists on disk
    while let Some(prev) = history.pop() {
        let prev_path = PathBuf::from(&prev);
        if prev_path.is_file() {
            // Re-insert as the newly active wallpaper
            history.push(prev);
            let _ = fs::write(hist_path, history.join("\n") + "\n");
            return Some(prev_path);
        }
    }

    // No valid previous wallpaper found; restore active wallpaper so history is preserved
    if let Some(c) = current {
        history.push(c);
    }
    let _ = fs::write(hist_path, history.join("\n") + "\n");
    None
}

pub fn pop_previous_wallpaper() -> Option<PathBuf> {
    let hist_path = history_file_path();
    pop_previous_wallpaper_from(&hist_path)
}

pub fn set_current_wallpaper(path: &Path) -> Result<(), std::io::Error> {
    let s_path = state_file_path();
    if let Some(parent) = s_path.parent() {
        fs::create_dir_all(parent)?;
    }
    record_history(path);
    fs::write(&s_path, format!("{}\n", path.display()))
}

#[cfg(test)]
mod tests {
    use super::*;

    struct TempDir {
        path: PathBuf,
    }

    impl TempDir {
        fn new(prefix: &str) -> Self {
            use std::sync::atomic::{AtomicU64, Ordering};
            static COUNTER: AtomicU64 = AtomicU64::new(0);
            let id = COUNTER.fetch_add(1, Ordering::Relaxed);
            let path = std::env::temp_dir().join(format!(
                "{prefix}_{}_{}_{}",
                std::process::id(),
                id,
                std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .map(|d| d.as_nanos())
                    .unwrap_or(0)
            ));
            let _ = fs::create_dir_all(&path);
            TempDir { path }
        }

        fn path(&self) -> &Path {
            &self.path
        }
    }

    impl Drop for TempDir {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.path);
        }
    }

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

    #[test]
    fn test_record_history_dedup() {
        let tmp = TempDir::new("test_wall_mgr_hist");
        let hist_path = tmp.path().join("wallpaper-history");
        let p1 = tmp.path().join("test_wall1_real.png");
        let p2 = tmp.path().join("test_wall2_real.png");
        let _ = fs::write(&p1, "mock1");
        let _ = fs::write(&p2, "mock2");

        // Use isolated file path with explicit current = None
        record_history_with_current(&p1, &hist_path, None);
        record_history_with_current(&p1, &hist_path, None); // Repeated should not duplicate
        record_history_with_current(&p2, &hist_path, None);

        let content = fs::read_to_string(&hist_path).expect("history file should exist");
        let lines: Vec<&str> = content.lines().collect();
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0], p1.to_str().unwrap());
        assert_eq!(lines[1], p2.to_str().unwrap());

        let popped = pop_previous_wallpaper_from(&hist_path);
        assert_eq!(popped, Some(p1.clone()));

        // Ensure isolated history path is kept within tempdir
        assert!(hist_path.starts_with(tmp.path()));
    }

    #[test]
    fn test_record_history_with_initial_current() {
        let tmp = TempDir::new("test_wall_mgr_init");
        let hist_path = tmp.path().join("wallpaper-history");
        let cur = tmp.path().join("initial.png");
        let next = tmp.path().join("next.png");
        let _ = fs::write(&cur, "cur");
        let _ = fs::write(&next, "next");

        record_history_with_current(&next, &hist_path, Some(&cur));

        let content = fs::read_to_string(&hist_path).expect("history file should exist");
        let lines: Vec<&str> = content.lines().collect();
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0], cur.to_str().unwrap());
        assert_eq!(lines[1], next.to_str().unwrap());
    }

    #[test]
    fn test_pop_previous_wallpaper_with_deleted_files() {
        let tmp = TempDir::new("test_wall_mgr_pop_deleted");
        let hist_path = tmp.path().join("wallpaper-history");
        let p_deleted = tmp.path().join("deleted.png");
        let p_valid1 = tmp.path().join("valid1.png");
        let p_valid2 = tmp.path().join("valid2.png");
        let _ = fs::write(&p_valid1, "v1");
        let _ = fs::write(&p_valid2, "v2");
        // p_deleted is intentionally not written to disk

        record_history_with_current(&p_deleted, &hist_path, None);
        record_history_with_current(&p_valid1, &hist_path, None);
        record_history_with_current(&p_valid2, &hist_path, None);

        // First pop: removes p_valid2, returns p_valid1
        let popped1 = pop_previous_wallpaper_from(&hist_path);
        assert_eq!(popped1, Some(p_valid1.clone()));

        // Second pop: p_deleted does not exist on disk, so it is pruned.
        // No valid previous entries remain, so p_valid1 must be preserved in history.
        let popped2 = pop_previous_wallpaper_from(&hist_path);
        assert_eq!(popped2, None);

        let content = fs::read_to_string(&hist_path).expect("history file should exist");
        let lines: Vec<&str> = content.lines().collect();
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0], p_valid1.to_str().unwrap());
    }

    #[test]
    fn test_pop_previous_wallpaper_single_entry() {
        let tmp = TempDir::new("test_wall_mgr_pop_single");
        let hist_path = tmp.path().join("wallpaper-history");
        let p1 = tmp.path().join("single.png");
        let _ = fs::write(&p1, "s1");

        record_history_with_current(&p1, &hist_path, None);

        // Single entry has no previous wallpaper
        let popped = pop_previous_wallpaper_from(&hist_path);
        assert_eq!(popped, None);

        let content = fs::read_to_string(&hist_path).expect("history file should exist");
        let lines: Vec<&str> = content.lines().collect();
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0], p1.to_str().unwrap());
    }
}
