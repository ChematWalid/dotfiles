//! Visual constants, dimensions, and Catppuccin Mocha palette for clipboard cards.

use image::Rgba;
use std::fs;
use std::os::unix::fs::{MetadataExt, PermissionsExt};
use std::path::{Path, PathBuf};
use std::time::SystemTime;

const MAX_CACHE_BYTES: u64 = 64 * 1024 * 1024;
const CACHE_TARGET_BYTES: u64 = 48 * 1024 * 1024;
const MAX_CACHE_FILES: usize = 512;
const CACHE_TARGET_FILES: usize = 384;

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

pub fn prune_cache(cache_dir: &Path) -> anyhow::Result<()> {
    prune_cache_with_thresholds(
        cache_dir,
        MAX_CACHE_BYTES,
        CACHE_TARGET_BYTES,
        MAX_CACHE_FILES,
        CACHE_TARGET_FILES,
    )
}

pub fn prune_cache_with_thresholds(
    cache_dir: &Path,
    max_bytes: u64,
    target_bytes: u64,
    max_files: usize,
    target_files: usize,
) -> anyhow::Result<()> {
    use std::fs::OpenOptions;

    let lock_path = cache_dir.join(".cache.lock");
    let lock_file = match OpenOptions::new()
        .create(true)
        .write(true)
        .truncate(false)
        .open(&lock_path)
    {
        Ok(f) => f,
        Err(e) => {
            eprintln!("rofi-clipboard: could not open cache lock file: {e}");
            return Ok(());
        }
    };

    // Non-blocking try_lock: if another instance is already pruning or active,
    // skip pruning without blocking the interactive UI.
    if lock_file.try_lock().is_err() {
        return Ok(());
    }

    let mut total_bytes = 0u64;
    let mut files = Vec::new();

    let entries = match fs::read_dir(cache_dir) {
        Ok(entries) => entries,
        Err(e) => {
            eprintln!("rofi-clipboard: could not read cache directory: {e}");
            return Ok(());
        }
    };

    for entry in entries {
        let entry = match entry {
            Ok(entry) => entry,
            Err(_) => continue,
        };
        if entry.file_name() == ".cache.lock" {
            continue;
        }

        match entry.file_type() {
            Ok(file_type) if file_type.is_file() => {}
            _ => continue,
        }
        let metadata = match entry.metadata() {
            Ok(metadata) => metadata,
            Err(_) => continue,
        };
        let size = metadata.len();
        total_bytes = total_bytes.saturating_add(size);
        files.push((
            metadata.modified().unwrap_or(SystemTime::UNIX_EPOCH),
            size,
            entry.path(),
        ));
    }

    if total_bytes <= max_bytes && files.len() <= max_files {
        return Ok(());
    }

    files.sort_unstable_by_key(|(modified, _, _)| *modified);
    let mut remaining_files = files.len();
    for (_, size, path) in files {
        if fs::remove_file(path).is_ok() {
            total_bytes = total_bytes.saturating_sub(size);
            remaining_files -= 1;
            if total_bytes <= target_bytes && remaining_files <= target_files {
                break;
            }
        }
    }

    Ok(())
}

// Catppuccin Mocha Colors
pub const BG_COLOR: Rgba<u8> = Rgba([24, 24, 37, 255]); // Mantle
pub const HEADER_BG: Rgba<u8> = Rgba([30, 30, 46, 255]); // Base
pub const ACCENT_COLOR: Rgba<u8> = Rgba([203, 166, 247, 255]); // Mauve
pub const FG_COLOR: Rgba<u8> = Rgba([205, 214, 244, 255]); // Text
pub const MUTED_COLOR: Rgba<u8> = Rgba([108, 112, 134, 255]); // Overlay0

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_prune_cache_within_threshold() {
        let dir = std::env::temp_dir().join(format!("rofi-test-1-{}", std::process::id()));
        let _ = fs::create_dir_all(&dir);
        let file1 = dir.join("file1.png");
        fs::write(&file1, b"hello").unwrap();

        prune_cache_with_thresholds(&dir, 1000, 500, 10, 5).unwrap();
        assert!(file1.exists());

        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn test_prune_cache_exceeding_threshold() {
        let dir = std::env::temp_dir().join(format!("rofi-test-2-{}", std::process::id()));
        let _ = fs::create_dir_all(&dir);
        let file1 = dir.join("old.png");
        let file2 = dir.join("new.png");
        fs::write(&file1, [0u8; 100]).unwrap();
        std::thread::sleep(std::time::Duration::from_millis(50));
        fs::write(&file2, [0u8; 100]).unwrap();

        // Total: 200 bytes across 2 files.
        // Max 150 bytes, target 100 bytes -> file1 (older, 100 bytes) should be removed, file2 retained.
        prune_cache_with_thresholds(&dir, 150, 100, 10, 5).unwrap();
        assert!(!file1.exists());
        assert!(file2.exists());

        let _ = fs::remove_dir_all(&dir);
    }

    #[test]
    fn test_prune_cache_non_blocking_when_locked() {
        let dir = std::env::temp_dir().join(format!("rofi-test-3-{}", std::process::id()));
        let _ = fs::create_dir_all(&dir);
        let lock_path = dir.join(".cache.lock");
        let lock_file = fs::OpenOptions::new()
            .create(true)
            .write(true)
            .open(&lock_path)
            .unwrap();
        lock_file.lock().unwrap();

        // Should return Ok(()) immediately without blocking
        let res = prune_cache_with_thresholds(&dir, 10, 5, 10, 5);
        assert!(res.is_ok());

        drop(lock_file);
        let _ = fs::remove_dir_all(&dir);
    }
}
