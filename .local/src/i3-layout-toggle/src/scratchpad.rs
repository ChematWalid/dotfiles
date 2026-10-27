//! Native Rust scratchpad terminal manager for i3.
//! Eliminates shell/jq forks and handles fullscreen window restoration robustly.

use std::env;
use std::fs::{self, File};
use std::io;
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use crate::ipc::I3Connection;

const CLASS_NAME: &str = "scratchpad_term";
const TITLE: &str = "__scratchpad_term__";

fn get_runtime_dir() -> PathBuf {
    env::var("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            let uid = unsafe { libc_getuid() };
            PathBuf::from(format!("/run/user/{uid}"))
        })
        .join("dotfiles")
}

unsafe fn libc_getuid() -> u32 {
    extern "C" {
        fn getuid() -> u32;
    }
    getuid()
}

fn acquire_scratchpad_lock(runtime_dir: &Path) -> Option<File> {
    let _ = fs::create_dir_all(runtime_dir);
    let lock_path = runtime_dir.join("scratchpad-toggle.lock");
    let file = fs::OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(false)
        .open(lock_path)
        .ok()?;

    use std::os::fd::AsRawFd;
    let fd = file.as_raw_fd();
    unsafe {
        extern "C" {
            fn flock(fd: std::os::raw::c_int, op: std::os::raw::c_int) -> std::os::raw::c_int;
        }
        const LOCK_EX: std::os::raw::c_int = 2;
        const LOCK_NB: std::os::raw::c_int = 4;
        if flock(fd, LOCK_EX | LOCK_NB) != 0 {
            return None;
        }
    }
    Some(file)
}

fn check_debounce(runtime_dir: &Path) -> bool {
    let stamp_path = runtime_dir.join("scratchpad-toggle.stamp");
    let now_ms = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0);

    if let Ok(content) = fs::read_to_string(&stamp_path) {
        if let Ok(last_ms) = content.trim().parse::<u64>() {
            if now_ms.saturating_sub(last_ms) < 200 {
                return false; // bounced
            }
        }
    }
    let _ = fs::write(stamp_path, now_ms.to_string());
    true
}

pub fn run_scratchpad_toggle() -> io::Result<()> {
    let runtime_dir = get_runtime_dir();
    let _lock = match acquire_scratchpad_lock(&runtime_dir) {
        Some(f) => f,
        None => return Ok(()),
    };

    if !check_debounce(&runtime_dir) {
        return Ok(());
    }

    let fs_state_file = runtime_dir.join("scratchpad-fullscreen.state");

    let mut i3 = I3Connection::connect()?;
    let tree = i3.get_tree()?;

    let scratch_node = tree.find_node_by_instance(CLASS_NAME);
    let focused_node = tree.find_focused();
    let focused_ws = focused_node.and_then(|f| tree.find_workspace_for_node(f.id));
    let fullscreen_id = focused_node
        .filter(|f| f.fullscreen_mode == 1)
        .map(|f| f.id)
        .unwrap_or(0);

    match scratch_node {
        None => {
            // Window not running yet: save fullscreen state if active, spawn Kitty, center
            if fullscreen_id != 0 {
                let _ = fs::write(&fs_state_file, fullscreen_id.to_string());
            }

            i3.run_command(&format!(
                "exec --no-startup-id kitty --class {CLASS_NAME} --title {TITLE}"
            ))?;

            // Wait up to 3 seconds for window to map in i3 tree
            let start = Instant::now();
            let mut found_id = None;
            while start.elapsed() < Duration::from_millis(3000) {
                std::thread::sleep(Duration::from_millis(50));
                if let Ok(new_tree) = i3.get_tree() {
                    if let Some(node) = new_tree.find_node_by_instance(CLASS_NAME) {
                        found_id = Some(node.id);
                        break;
                    }
                }
            }

            if let Some(id) = found_id {
                let _ = i3.run_command(&format!(
                    "[id=\"{id}\"] floating enable, resize set 900 550, move position center, focus"
                ));
            }
        }
        Some(node) => {
            let scratch_ws = tree.find_workspace_for_node(node.id);
            let is_on_current_ws = match (scratch_ws, focused_ws) {
                (Some(sws), Some(cws)) => sws.id == cws.id,
                _ => false,
            };

            if is_on_current_ws {
                // Scratchpad is visible on current workspace -> HIDE IT
                i3.run_command(&format!("[instance=\"{CLASS_NAME}\"] move to scratchpad"))?;

                // Restore fullscreen if a window was fullscreen before scratchpad was opened
                if fs_state_file.exists() {
                    if let Ok(content) = fs::read_to_string(&fs_state_file) {
                        let _ = fs::remove_file(&fs_state_file);
                        if let Ok(fs_id) = content.trim().parse::<i64>() {
                            if fs_id != 0 && tree.find_node_by_id(fs_id).is_some() {
                                let _ = i3.run_command(&format!("[id=\"{fs_id}\"] fullscreen enable"));
                            }
                        }
                    }
                }
            } else {
                // Scratchpad is hidden in __i3_scratch or on another workspace -> SHOW IT HERE
                if fullscreen_id != 0 {
                    let _ = fs::write(&fs_state_file, fullscreen_id.to_string());
                } else {
                    let _ = fs::remove_file(&fs_state_file);
                }

                i3.run_command(&format!(
                    "[instance=\"{CLASS_NAME}\"] scratchpad show, floating enable, resize set 900 550, move position center, focus"
                ))?;
            }
        }
    }

    Ok(())
}
