//! Media state representation and querying.

use std::collections::HashMap;
use zbus::{Connection, OwnedVariant};

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct MediaState {
    pub player: String,
    pub status: String,
    pub full_text: String,
    pub full_text_chars: usize,
}

pub async fn query_current_state(conn: &Connection) -> MediaState {
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
        Err(_) => return MediaState::default(),
    };
    let Ok(names) = names_reply.body().deserialize::<Vec<String>>() else {
        return MediaState::default();
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
        if status != "Playing" && (status != "Paused" || paused.is_some()) {
            continue;
        }

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
        if artist.is_empty() && title.is_empty() {
            continue;
        }

        let full_text = match (artist.is_empty(), title.is_empty()) {
            (false, false) => format!("{artist} - {title}"),
            (true, false) => title,
            (false, true) => artist,
            (true, true) => continue,
        };
        let state = MediaState {
            player: name
                .strip_prefix("org.mpris.MediaPlayer2.")
                .unwrap_or(name)
                .to_string(),
            status: status.clone(),
            full_text_chars: full_text.chars().count(),
            full_text,
        };

        if status == "Playing" {
            return state;
        }
        paused = Some(state);
    }

    paused.unwrap_or_default()
}
