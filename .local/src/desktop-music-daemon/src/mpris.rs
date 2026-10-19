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
