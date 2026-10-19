//! Media state representation and querying.

use std::process::Stdio;
use tokio::process::Command;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MediaState {
    pub player: String,
    pub status: String,
    pub full_text: String,
}

pub async fn query_current_state() -> MediaState {
    let out = Command::new("playerctl")
        .args([
            "metadata",
            "-a",
            "--format",
            "{{playerName}}:::{{status}}:::{{artist}}:::{{title}}",
        ])
        .stderr(Stdio::null())
        .output()
        .await;

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<MediaState> = None;
        let mut paused: Option<MediaState> = None;

        for line in stdout.lines() {
            let mut parts = line.splitn(5, ":::");
            let (Some(player), Some(status), Some(artist), Some(title)) =
                (parts.next(), parts.next(), parts.next(), parts.next())
            else {
                continue;
            };
            let player = player.trim().to_string();
            let status = status.trim().to_string();
            let artist = artist.trim();
            let title = title.trim();

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
