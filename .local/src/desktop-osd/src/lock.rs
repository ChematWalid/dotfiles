use std::fs::{self, File, OpenOptions};
use std::os::fd::AsRawFd;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

pub fn get_runtime_dir() -> PathBuf {
    let base = std::env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| {
        let uid = unsafe { libc_getuid() };
        format!("/run/user/{uid}")
    });
    let dir = PathBuf::from(base).join("dotfiles");
    let _ = fs::create_dir_all(&dir);
    dir
}

unsafe fn libc_getuid() -> u32 {
    extern "C" {
        fn getuid() -> u32;
    }
    getuid()
}

pub struct FileLock {
    _file: File,
}

impl FileLock {
    pub fn try_acquire(lock_path: &Path, timeout: Duration) -> Option<Self> {
        if let Some(parent) = lock_path.parent() {
            let _ = fs::create_dir_all(parent);
        }

        let file = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(false)
            .open(lock_path)
            .ok()?;

        let fd = file.as_raw_fd();
        let start = Instant::now();

        loop {
            let ret = unsafe {
                extern "C" {
                    fn flock(fd: std::os::raw::c_int, op: std::os::raw::c_int) -> std::os::raw::c_int;
                }
                const LOCK_EX: std::os::raw::c_int = 2;
                const LOCK_NB: std::os::raw::c_int = 4;
                flock(fd, LOCK_EX | LOCK_NB)
            };

            if ret == 0 {
                return Some(Self { _file: file });
            }

            if start.elapsed() >= timeout {
                return None;
            }

            std::thread::sleep(Duration::from_millis(5));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_lock_acquire_and_release() {
        let temp_dir = std::env::temp_dir();
        let lock_path = temp_dir.join("test-desktop-osd.lock");

        let lock1 = FileLock::try_acquire(&lock_path, Duration::from_millis(100));
        assert!(lock1.is_some());

        // Second lock while first is held should fail
        let lock2 = FileLock::try_acquire(&lock_path, Duration::from_millis(20));
        assert!(lock2.is_none());

        drop(lock1);

        // After dropping first lock, acquiring should succeed
        let lock3 = FileLock::try_acquire(&lock_path, Duration::from_millis(100));
        assert!(lock3.is_some());
        drop(lock3);

        let _ = fs::remove_file(lock_path);
    }
}
