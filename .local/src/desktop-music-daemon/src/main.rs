//! desktop-music-daemon — Real-time MPRIS music display daemon for Conky desktop.
//! Converted to Rust with asynchronous event streaming for zero-latency desktop updates.

use std::fs;
use std::process::{self, Command as SyncCommand, Stdio};
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::time::{sleep, Duration};

const OUTPUT_FILE: &str = "/tmp/conky-music.txt";
const TMP_FILE: &str = "/tmp/conky-music.txt.tmp";
const PID_FILE: &str = "/tmp/.desktop-music-daemon.pid";

fn write_output_atomic(text: &str) {
    let _ = fs::write(TMP_FILE, text.trim())
        .and_then(|_| fs::rename(TMP_FILE, OUTPUT_FILE));
}

fn ensure_single_instance() {
    let my_pid = process::id();
    if let Ok(contents) = fs::read_to_string(PID_FILE) {
        if let Ok(old_pid) = contents.trim().parse::<u32>() {
            if old_pid != my_pid {
                let _ = SyncCommand::new("kill")
                    .args(["-9", &old_pid.to_string()])
                    .output();
            }
        }
    }
    let _ = fs::write(PID_FILE, my_pid.to_string());
}

fn query_current_state() -> String {
    // 1. Check playerctl first
    let out = SyncCommand::new("playerctl")
        .args(["metadata", "-a", "--format", "{{status}}:::{{artist}}:::{{title}}"])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing_entry = None;
        let mut paused_entry = None;

        for line in stdout.lines() {
            let parts: Vec<&str> = line.split(":::").collect();
            if parts.is_empty() {
                continue;
            }
            let status = parts[0];
            let artist = parts.get(1).cloned().unwrap_or("").trim();
            let title = parts.get(2).cloned().unwrap_or("").trim();

            let full = if !artist.is_empty() && !title.is_empty() {
                format!("{} - {}", artist, title)
            } else if !title.is_empty() {
                title.to_string()
            } else if !artist.is_empty() {
                artist.to_string()
            } else {
                continue;
            };

            if status == "Playing" && playing_entry.is_none() {
                playing_entry = Some(format!("\u{f040a} {}", full));
            } else if status == "Paused" && paused_entry.is_none() {
                paused_entry = Some(format!("\u{f03e4} {}", full));
            }
        }

        if let Some(p) = playing_entry {
            return p;
        }
        if let Some(p) = paused_entry {
            return p;
        }
    }

    // 2. Fallback: mpc current
    if let Ok(out) = SyncCommand::new("mpc")
        .arg("current")
        .stderr(Stdio::null())
        .output()
    {
        let mpc = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !mpc.is_empty() {
            return format!("\u{f040a} {}", mpc);
        }
    }

    String::new()
}

#[tokio::main]
async fn main() {
    ensure_single_instance();

    // Initial state
    let mut current_text = query_current_state();
    write_output_atomic(&current_text);

    // Background heartbeat / fallback poll every 500ms
    tokio::spawn(async {
        loop {
            sleep(Duration::from_millis(500)).await;
            let latest = query_current_state();
            write_output_atomic(&latest);
        }
    });

    // Real-time event stream via playerctl --follow
    loop {
        let child = Command::new("playerctl")
            .args(["metadata", "-a", "--format", "{{status}}:::{{artist}}:::{{title}}", "--follow"])
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn();

        let mut child = match child {
            Ok(c) => c,
            Err(_) => {
                sleep(Duration::from_secs(1)).await;
                continue;
            }
        };

        let stdout = match child.stdout.take() {
            Some(s) => s,
            None => {
                sleep(Duration::from_secs(1)).await;
                continue;
            }
        };

        let reader = BufReader::new(stdout);
        let mut lines = reader.lines();

        while let Ok(Some(line)) = lines.next_line().await {
            let parts: Vec<&str> = line.split(":::").collect();
            if parts.is_empty() {
                continue;
            }
            let status = parts[0].trim();
            let artist = parts.get(1).cloned().unwrap_or("").trim();
            let title = parts.get(2).cloned().unwrap_or("").trim();

            let new_text = if status == "Stopped" || status == "No players found" {
                String::new()
            } else if !artist.is_empty() || !title.is_empty() {
                let full = if !artist.is_empty() && !title.is_empty() {
                    format!("{} - {}", artist, title)
                } else if !title.is_empty() {
                    title.to_string()
                } else {
                    artist.to_string()
                };
                if status == "Playing" {
                    format!("\u{f040a} {}", full)
                } else {
                    format!("\u{f03e4} {}", full)
                }
            } else {
                // Empty artist/title in event — Chromium pause/status-only events
                // Always fall through to authoritative query
                query_current_state()
            };

            if new_text != current_text {
                current_text = new_text.clone();
                write_output_atomic(&current_text);
            }
        }

        // If playerctl exited (e.g., player closed), refresh state immediately
        let new_text = query_current_state();
        current_text = new_text.clone();
        write_output_atomic(&current_text);
        sleep(Duration::from_millis(500)).await;
    }
}
