//! Media state representation and querying.

use std::process::{Command as SyncCommand, Stdio};

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MediaState {
    pub player: String,
    pub status: String,
    pub full_text: String,
}

pub fn query_current_state() -> MediaState {
    let out = SyncCommand::new("playerctl")
        .args([
            "metadata",
            "-a",
            "--format",
            "{{playerName}}:::{{status}}:::{{artist}}:::{{title}}",
        ])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<MediaState> = None;
        let mut paused: Option<MediaState> = None;

        for line in stdout.lines() {
            let p: Vec<&str> = line.splitn(5, ":::").collect();
            if p.len() < 4 {
                continue;
            }
            let player = p[0].trim().to_string();
            let status = p[1].trim().to_string();
            let artist = p[2].trim();
            let title = p[3].trim();

            if artist.is_empty() && title.is_empty() {
                continue;
            }

            let full_text = match (artist.is_empty(), title.is_empty()) {
                (false, false) => format!("{} - {}", artist, title),
                (true, false) => title.to_string(),
                _ => artist.to_string(),
            };

            let st = MediaState {
                player,
                status: status.clone(),
                full_text,
            };

            if status == "Playing" && playing.is_none() {
                playing = Some(st);
            } else if status == "Paused" && paused.is_none() {
                paused = Some(st);
            }

            if playing.is_some() {
                break;
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
