//! mpris-live — Real-time Polybar MPRIS module + Conky desktop synchronizer in Rust.
//! Updates both Polybar and Conky synchronously in real time on any media event.

use std::fs;
use std::io::{stdout, Write};
use std::process::{self, Command as SyncCommand, Stdio};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, BufReader};
use tokio::process::Command;
use tokio::sync::Mutex;
use tokio::time::{interval, sleep, Duration};

const MAX_CHARS: usize = 18;
const SCROLL_INTERVAL_MS: u64 = 180;
const SEPARATOR: &str = "   •   ";
const CONKY_FILE: &str = "/tmp/conky-music.txt";
const CONKY_TMP: &str = "/tmp/conky-music.txt.tmp";
const PID_FILE: &str = "/tmp/.polybar-mpris-live.pid";

#[derive(Debug, Clone, Default)]
struct MediaState {
    player: String,
    status: String, // "Playing", "Paused", "Stopped"
    artist: String,
    title: String,
    full_text: String,
}

fn write_conky(status: &str, full_text: &str) {
    let conky_text = if status == "Playing" && !full_text.is_empty() {
        format!("\u{f040a} {}", full_text)
    } else if status == "Paused" && !full_text.is_empty() {
        format!("\u{f03e4} {}", full_text)
    } else {
        String::new()
    };
    let _ = fs::write(CONKY_TMP, conky_text.trim())
        .and_then(|_| fs::rename(CONKY_TMP, CONKY_FILE));
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

fn query_current_state() -> MediaState {
    let out = SyncCommand::new("playerctl")
        .args(["metadata", "-a", "--format", "{{playerName}}:::{{status}}:::{{artist}}:::{{title}}"])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing = None;
        let mut paused = None;

        for line in stdout.lines() {
            let parts: Vec<&str> = line.split(":::").collect();
            if parts.len() < 2 {
                continue;
            }
            let player = parts[0].trim().to_string();
            let status = parts[1].trim().to_string();
            let artist = parts.get(2).cloned().unwrap_or("").trim().to_string();
            let title = parts.get(3).cloned().unwrap_or("").trim().to_string();

            let full_text = if !artist.is_empty() && !title.is_empty() {
                format!("{} - {}", artist, title)
            } else if !title.is_empty() {
                title.clone()
            } else if !artist.is_empty() {
                artist.clone()
            } else {
                "Media".to_string()
            };

            let state = MediaState {
                player,
                status: status.clone(),
                artist,
                title,
                full_text,
            };

            if status == "Playing" && playing.is_none() {
                playing = Some(state);
            } else if status == "Paused" && paused.is_none() {
                paused = Some(state);
            }
        }

        if let Some(s) = playing {
            return s;
        }
        if let Some(s) = paused {
            return s;
        }
    }

    MediaState::default()
}

fn is_mouse_hovering() -> bool {
    let out = SyncCommand::new("xdotool")
        .arg("getmouselocation")
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let s = String::from_utf8_lossy(&out.stdout);
        let mut x = -1i32;
        let mut y = -1i32;
        for token in s.split_whitespace() {
            if let Some(rest) = token.strip_prefix("x:") {
                x = rest.parse().unwrap_or(-1);
            } else if let Some(rest) = token.strip_prefix("y:") {
                y = rest.parse().unwrap_or(-1);
            }
        }
        return y >= 720 && x >= 400 && x <= 920;
    }
    false
}

fn get_marquee_slice(text: &str, offset: usize, hovering: bool) -> String {
    let char_count = text.chars().count();
    if char_count <= MAX_CHARS {
        return text.to_string();
    }

    if !hovering {
        let prefix: String = text.chars().take(MAX_CHARS - 1).collect();
        return format!("{}…", prefix);
    }

    let stream = format!("{}{}", text, SEPARATOR);
    let stream_chars: Vec<char> = stream.chars().collect();
    let stream_len = stream_chars.len();
    let idx = offset % stream_len;

    let doubled: Vec<char> = stream_chars.iter().chain(stream_chars.iter()).copied().collect();
    doubled[idx..idx + MAX_CHARS].iter().collect()
}

fn render(state: &MediaState, scroll_pos: usize, hovering: bool) -> String {
    if state.player.is_empty()
        || state.status.is_empty()
        || state.status == "Stopped"
        || state.full_text.is_empty()
    {
        return String::new();
    }

    // Play/pause icon:
    // Playing -> pause circle (󰏥 in green)
    // Paused  -> play circle (󰐌 in yellow)
    let play_icon = if state.status == "Playing" {
        "%{F#a6e3a1}\u{f03e5}%{F-}"
    } else {
        "%{F#f9e2af}\u{f040c}%{F-}"
    };

    let display_text = get_marquee_slice(&state.full_text, scroll_pos, hovering);

    let prev = format!(
        "%{{F#89b4fa}}%{{A1:playerctl -p {} previous 2>/dev/null:}}\u{f04ae}%{{A}}%{{F-}}",
        state.player
    );
    let play = format!(
        "%{{A1:playerctl -p {} play-pause 2>/dev/null:}}{}%{{A}}",
        state.player, play_icon
    );
    let next = format!(
        "%{{F#89b4fa}}%{{A1:playerctl -p {} next 2>/dev/null:}}\u{f04ad}%{{A}}%{{F-}}",
        state.player
    );
    let note = "%{F#f5c2e7}\u{f0386}%{F-}";

    format!(
        "%{{T4}}{}  {}  {}%{{T-}}   {} %{{F#cdd6f4}}{}%{{F-}}",
        prev, play, next, note, display_text
    )
}

#[tokio::main]
async fn main() {
    ensure_single_instance();

    let state = Arc::new(Mutex::new(query_current_state()));
    let hovering = Arc::new(AtomicBool::new(false));

    // Initial Conky write
    {
        let st = state.lock().await;
        write_conky(&st.status, &st.full_text);
    }

    // Task 1: Hover detection loop (polls every 150ms)
    let hovering_clone = Arc::clone(&hovering);
    tokio::spawn(async move {
        let mut ticker = interval(Duration::from_millis(150));
        loop {
            ticker.tick().await;
            let is_h = is_mouse_hovering();
            hovering_clone.store(is_h, Ordering::Relaxed);
        }
    });

    // Task 2: Real-time listener using playerctl --follow
    let state_listener = Arc::clone(&state);
    tokio::spawn(async move {
        loop {
            let child = Command::new("playerctl")
                .args(["metadata", "-a", "--format", "{{playerName}}:::{{status}}:::{{artist}}:::{{title}}", "--follow"])
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

            while let Ok(Some(_)) = lines.next_line().await {
                // Whenever ANY metadata/status event occurs, query best active player immediately
                let latest = query_current_state();
                write_conky(&latest.status, &latest.full_text);
                let mut st = state_listener.lock().await;
                *st = latest;
            }

            // Player closed / exited
            let latest = query_current_state();
            write_conky(&latest.status, &latest.full_text);
            let mut st = state_listener.lock().await;
            *st = latest;
            sleep(Duration::from_millis(500)).await;
        }
    });

    // Task 3: Heartbeat check every 500ms
    let state_heartbeat = Arc::clone(&state);
    tokio::spawn(async move {
        let mut ticker = interval(Duration::from_millis(500));
        loop {
            ticker.tick().await;
            let latest = query_current_state();
            write_conky(&latest.status, &latest.full_text);
            let mut st = state_heartbeat.lock().await;
            *st = latest;
        }
    });

    // Main render loop for Polybar stdout
    let mut scroll_pos = 0usize;
    let mut last_rendered = String::new();
    let mut last_text = String::new();
    let mut ticker = interval(Duration::from_millis(SCROLL_INTERVAL_MS));

    loop {
        ticker.tick().await;
        let is_h = hovering.load(Ordering::Relaxed);

        let current_state = {
            let st = state.lock().await;
            st.clone()
        };

        if current_state.full_text != last_text {
            scroll_pos = 0;
            last_text = current_state.full_text.clone();
        }

        let rendered = render(&current_state, scroll_pos, is_h);

        if rendered != last_rendered {
            println!("{}", rendered);
            let _ = stdout().flush();
            last_rendered = rendered;
        }

        let text_char_len = current_state.full_text.chars().count();
        if is_h && text_char_len > MAX_CHARS {
            let stream_len = text_char_len + SEPARATOR.chars().count();
            scroll_pos = (scroll_pos + 1) % stream_len;
        } else if !is_h {
            scroll_pos = 0;
        }
    }
}
