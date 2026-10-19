//! MPRIS player state querying and D-Bus signal subscription.

use crate::config::{ICON_PAUSE, ICON_PLAY};
use anyhow::Result;
use std::collections::HashMap;
use std::process::Stdio;
use tokio::process::Command;
use zbus::{message::Type as MsgType, Connection, MatchRule, Message, MessageStream, OwnedVariant};

/// Queries playerctl for the highest priority active player:
/// Prefers Playing > Paused. Falls back to MPD via `mpc current`.
pub async fn query_current_state() -> String {
    let out = Command::new("playerctl")
        .args([
            "metadata",
            "-a",
            "--format",
            "{{status}}:::{{artist}}:::{{title}}",
        ])
        .stderr(Stdio::null())
        .output()
        .await;

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<String> = None;
        let mut paused: Option<String> = None;

        for line in stdout.lines() {
            let mut parts = line.splitn(4, ":::");
            let (Some(status), Some(artist), Some(title)) =
                (parts.next(), parts.next(), parts.next())
            else {
                continue;
            };
            let status = status.trim();
            let artist = artist.trim();
            let title = title.trim();

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
    if let Ok(out) = Command::new("mpc")
        .arg("current")
        .stderr(Stdio::null())
        .output()
        .await
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
        .interface("org.freedesktop.DBus.Properties")
        .member("PropertiesChanged")
        .path("/org/mpris/MediaPlayer2")
        .build()?;

    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")
        .interface("org.freedesktop.DBus")
        .member("NameOwnerChanged")
        .build()?;

    let props_stream = MessageStream::for_match_rule(props_rule, conn, None).await?;
    let name_stream = MessageStream::for_match_rule(name_rule, conn, None).await?;

    Ok((props_stream, name_stream))
}

/// Return true only for player properties that affect the displayed track.
/// Unknown signal bodies are refreshed conservatively to avoid stale output.
pub fn affects_displayed_state(message: &Message) -> bool {
    let body: Result<(String, HashMap<String, OwnedVariant>, Vec<String>), _> =
        message.body().deserialize();
    let Ok((interface, changed, invalidated)) = body else {
        return true;
    };
    if interface != "org.mpris.MediaPlayer2.Player" {
        return false;
    }

    ["PlaybackStatus", "Metadata"].iter().any(|property| {
        changed.contains_key(*property) || invalidated.iter().any(|key| key == property)
    })
}
