//! MPRIS player state querying and D-Bus signal subscription.

use crate::config::{ICON_PAUSE, ICON_PLAY};
use anyhow::Result;
use std::process::{Command as SyncCommand, Stdio};
use zbus::{message::Type as MsgType, Connection, MatchRule, MessageStream};

/// Queries playerctl for the highest priority active player:
/// Prefers Playing > Paused. Falls back to MPD via `mpc current`.
pub fn query_current_state() -> String {
    let out = SyncCommand::new("playerctl")
        .args([
            "metadata",
            "-a",
            "--format",
            "{{status}}:::{{artist}}:::{{title}}",
        ])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<String> = None;
        let mut paused: Option<String> = None;

        for line in stdout.lines() {
            let p: Vec<&str> = line.splitn(4, ":::").collect();
            if p.len() < 3 {
                continue;
            }
            let status = p[0].trim();
            let artist = p[1].trim();
            let title = p[2].trim();

            if artist.is_empty() && title.is_empty() {
                continue;
            }

            let full = match (artist.is_empty(), title.is_empty()) {
                (false, false) => format!("{} - {}", artist, title),
                (true, false) => title.to_string(),
                _ => artist.to_string(),
            };

            if status == "Playing" && playing.is_none() {
                playing = Some(format!("{} {}", ICON_PLAY, full));
            } else if status == "Paused" && paused.is_none() {
                paused = Some(format!("{} {}", ICON_PAUSE, full));
            }

            if playing.is_some() {
                break;
            }
        }

        if let Some(t) = playing {
            return t;
        }
        if let Some(t) = paused {
            return t;
        }
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

/// Sets up D-Bus event streams for PropertiesChanged and NameOwnerChanged signals.
pub async fn setup_dbus_streams(conn: &Connection) -> Result<(MessageStream, MessageStream)> {
    let props_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path("/org/mpris/MediaPlayer2")?
        .build();

    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")?
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .build();

    let props_stream = MessageStream::for_match_rule(props_rule, conn, None).await?;
    let name_stream = MessageStream::for_match_rule(name_rule, conn, None).await?;

    Ok((props_stream, name_stream))
}
