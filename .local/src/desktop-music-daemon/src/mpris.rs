//! MPRIS player state querying and D-Bus signal subscription.

use crate::config::{ICON_PAUSE, ICON_PLAY};
use anyhow::Result;
use std::collections::HashMap;
use zbus::{message::Type as MsgType, Connection, MatchRule, Message, MessageStream, OwnedVariant};

/// Queries active MPRIS players directly over D-Bus, preferring Playing > Paused.
/// MPD remains a fallback through `mpc current` when no MPRIS player has metadata.
pub async fn query_current_state(conn: &Connection) -> String {
    let names_reply = match conn
        .call_method(
            Some("org.freedesktop.DBus"),
            "/org/freedesktop/DBus",
            Some("org.freedesktop.DBus"),
            "ListNames",
            &(),
        )
        .await
    {
        Ok(reply) => reply,
        Err(_) => return query_mpd().await,
    };
    let names: Vec<String> = match names_reply.body().deserialize() {
        Ok(names) => names,
        Err(_) => return query_mpd().await,
    };

    let mut paused = None;
    for name in names.iter().filter(|name| name.starts_with("org.mpris.")) {
        let properties_reply = match conn
            .call_method(
                Some(name.as_str()),
                "/org/mpris/MediaPlayer2",
                Some("org.freedesktop.DBus.Properties"),
                "GetAll",
                &("org.mpris.MediaPlayer2.Player",),
            )
            .await
        {
            Ok(reply) => reply,
            Err(_) => continue,
        };
        let Ok(properties) = properties_reply
            .body()
            .deserialize::<HashMap<String, OwnedVariant>>()
        else {
            continue;
        };
        let Some(status) = properties
            .get("PlaybackStatus")
            .and_then(|value| String::try_from(value.try_clone().ok()?).ok())
        else {
            continue;
        };
        let icon = match status.as_str() {
            "Playing" => ICON_PLAY,
            "Paused" if paused.is_none() => ICON_PAUSE,
            _ => continue,
        };

        let Some(metadata) = properties.get("Metadata").and_then(|value| {
            HashMap::<String, OwnedVariant>::try_from(value.try_clone().ok()?).ok()
        }) else {
            continue;
        };
        let artist = metadata
            .get("xesam:artist")
            .and_then(|value| Vec::<String>::try_from(value.try_clone().ok()?).ok())
            .unwrap_or_default()
            .join(", ");
        let title = metadata
            .get("xesam:title")
            .and_then(|value| String::try_from(value.try_clone().ok()?).ok())
            .unwrap_or_default();

        let full = match (artist.is_empty(), title.is_empty()) {
            (false, false) => format!("{artist} - {title}"),
            (true, false) => title,
            (false, true) => artist,
            (true, true) => continue,
        };
        let full = truncate_text(&full, crate::config::MAX_DISPLAY_CHARS);
        let text = format!("{icon} {full}");

        if status == "Playing" {
            return text;
        }
        paused = Some(text);
    }

    if let Some(text) = paused {
        return text;
    }
    query_mpd().await
}

/// Truncates a string to at most `max_chars` Unicode characters safely.
/// Preserves UTF-8 character boundaries to prevent indexing panics on multi-byte characters
/// (such as Arabic, CJK, emoji, and accented glyphs).
pub fn truncate_text(text: &str, max_chars: usize) -> String {
    if max_chars == 0 {
        return String::new();
    }
    let mut char_indices = text.char_indices();
    if char_indices.nth(max_chars).is_none() {
        return text.to_string();
    }

    let target_chars = max_chars.saturating_sub(1);
    let end_byte = if target_chars == 0 {
        0
    } else {
        text.char_indices()
            .nth(target_chars)
            .map(|(idx, _)| idx)
            .unwrap_or(text.len())
    };
    let mut truncated = String::with_capacity(end_byte + '…'.len_utf8());
    truncated.push_str(&text[..end_byte]);
    truncated.push('…');
    truncated
}

async fn query_mpd() -> String {
    // Fallback: mpc (MPD)
    let Ok(output) = tokio::process::Command::new("mpc")
        .arg("current")
        .stderr(std::process::Stdio::null())
        .output()
        .await
    else {
        return String::new();
    };
    let current = String::from_utf8_lossy(&output.stdout);
    let current = current.trim();
    if !current.is_empty() {
        let current = truncate_text(current, crate::config::MAX_DISPLAY_CHARS);
        return format!("{} {current}", ICON_PLAY);
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
        .arg(0, "org.mpris.MediaPlayer2.Player")
        .build()?;

    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")
        .interface("org.freedesktop.DBus")
        .member("NameOwnerChanged")
        .arg0ns("org.mpris")
        .build()?;

    let props_stream = MessageStream::for_match_rule(props_rule, conn, None).await?;
    let name_stream = MessageStream::for_match_rule(name_rule, conn, None).await?;

    Ok((props_stream, name_stream))
}

/// Return true only for player properties that affect the displayed track.
/// Unknown signal bodies are refreshed conservatively to avoid stale output.
pub fn affects_displayed_state(message: &Message) -> bool {
    let body_ref = message.body();
    let body: Result<(&str, HashMap<&str, zbus::Variant>, Vec<&str>), _> =
        body_ref.deserialize();
    let Ok((interface, changed, invalidated)) = body else {
        return true;
    };
    if interface != "org.mpris.MediaPlayer2.Player" {
        return false;
    }

    let watched = ["PlaybackStatus", "Metadata"];
    watched.iter().any(|property| {
        changed.contains_key(*property) || invalidated.iter().any(|key| key == property)
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_truncate_text_within_bounds() {
        assert_eq!(truncate_text("Short Song", 65), "Short Song");
        assert_eq!(truncate_text("Exact Length", 12), "Exact Length");
    }

    #[test]
    fn test_truncate_text_exceeding_bounds() {
        let long_text = "This is a very long artist and track name that surely exceeds thirty characters limit";
        let truncated = truncate_text(long_text, 30);
        assert_eq!(truncated.chars().count(), 30);
        assert!(truncated.ends_with('…'));
    }

    #[test]
    fn test_truncate_text_multibyte_utf8() {
        // Arabic multi-byte characters (2 bytes each)
        let arabic = "فيروز - قمرة يا قمرة يا شمعة مضواية تنزل على الحارة وتفرش حكاية";
        let truncated = truncate_text(arabic, 20);
        assert_eq!(truncated.chars().count(), 20);
        assert!(truncated.ends_with('…'));

        // CJK multi-byte characters (3 bytes each)
        let cjk = "久石譲 - あの夏へ (Spirited Away Soundtrack Original Album)";
        let truncated_cjk = truncate_text(cjk, 15);
        assert_eq!(truncated_cjk.chars().count(), 15);
        assert!(truncated_cjk.ends_with('…'));

        // Emoji characters (4 bytes each)
        let emoji = "🎵🎶🎧🎹🎸🎺🎻🥁🎵🎶🎧🎹🎸🎺🎻🥁";
        let truncated_emoji = truncate_text(emoji, 5);
        assert_eq!(truncated_emoji.chars().count(), 5);
        assert!(truncated_emoji.ends_with('…'));
    }

    #[test]
    fn test_truncate_text_edge_cases() {
        assert_eq!(truncate_text("", 65), "");
        assert_eq!(truncate_text("A", 0), "");
        assert_eq!(truncate_text("AB", 1), "…");
    }
}
