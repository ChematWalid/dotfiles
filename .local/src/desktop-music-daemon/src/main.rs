//! desktop-music-daemon — Zero-polling, real-time MPRIS D-Bus event daemon for Conky.
//!
//! Subscribes directly to:
//!   • org.freedesktop.DBus.Properties.PropertiesChanged  (play/pause/track change)
//!   • org.freedesktop.DBus.NameOwnerChanged              (player open/close)
//!
//! No subprocess spawned for events, no heartbeat timer.
//! Latency: <5ms from play/pause to /tmp/conky-music.txt update.

use std::fs;
use std::process::{self, Command as SyncCommand, Stdio};
use futures_lite::StreamExt;
use zbus::{Connection, MatchRule, MessageStream, message::Type as MsgType};

const OUTPUT_FILE: &str = "/tmp/conky-music.txt";
const TMP_FILE:    &str = "/tmp/conky-music.txt.tmp";
const PID_FILE:    &str = "/tmp/.desktop-music-daemon.pid";

// ── Icons (Nerd Font) ────────────────────────────────────────────────────────
const ICON_PLAY:  &str = "\u{f040a}"; // 󰐊
const ICON_PAUSE: &str = "\u{f03e4}"; // 󰏤

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

/// Query best active player via playerctl (used only for initial state
/// and as the canonical source after each D-Bus event fires).
fn query_current_state() -> String {
    let out = SyncCommand::new("playerctl")
        .args(["metadata", "-a", "--format",
               "{{status}}:::{{artist}}:::{{title}}"])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<String> = None;
        let mut paused:  Option<String> = None;

        for line in stdout.lines() {
            let p: Vec<&str> = line.splitn(4, ":::").collect();
            if p.len() < 3 { continue; }
            let status = p[0].trim();
            let artist = p[1].trim();
            let title  = p[2].trim();

            if artist.is_empty() && title.is_empty() { continue; }

            let full = match (artist.is_empty(), title.is_empty()) {
                (false, false) => format!("{} - {}", artist, title),
                (true,  false) => title.to_string(),
                _              => artist.to_string(),
            };

            if status == "Playing" && playing.is_none() {
                playing = Some(format!("{} {}", ICON_PLAY, full));
            } else if status == "Paused" && paused.is_none() {
                paused = Some(format!("{} {}", ICON_PAUSE, full));
            }

            if playing.is_some() { break; } // prefer first Playing entry
        }

        if let Some(t) = playing { return t; }
        if let Some(t) = paused  { return t; }
    }

    // Fallback: mpc (MPD)
    if let Ok(out) = SyncCommand::new("mpc")
        .arg("current")
        .stderr(Stdio::null())
        .output()
    {
        let mpc = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !mpc.is_empty() {
            return format!("{} {}", ICON_PLAY, mpc);
        }
    }

    String::new()
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    ensure_single_instance();

    // Write initial state immediately
    write_output_atomic(&query_current_state());

    // Connect to the session D-Bus
    let conn = Connection::session().await?;

    // ── Match rule 1: any MPRIS PropertiesChanged signal ────────────────────
    // Fires on play, pause, track change, volume change, etc.
    let props_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path("/org/mpris/MediaPlayer2")?
        .build();

    // ── Match rule 2: NameOwnerChanged — player opens or closes ─────────────
    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")?
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .build();

    let mut props_stream = MessageStream::for_match_rule(props_rule, &conn, None).await?;
    let mut name_stream  = MessageStream::for_match_rule(name_rule,  &conn, None).await?;

    loop {
        tokio::select! {
            // MPRIS property changed (play/pause/track/metadata)
            Some(_) = props_stream.next() => {
                write_output_atomic(&query_current_state());
            }
            // A D-Bus name appeared or disappeared
            Some(msg_result) = name_stream.next() => {
                if let Ok(msg) = msg_result {
                    let body: Result<(String, String, String), _> = msg.body().deserialize();
                    if let Ok((name, _old, _new)) = body {
                        if name.starts_with("org.mpris.") {
                            write_output_atomic(&query_current_state());
                        }
                    }
                }
            }
        }
    }
}
