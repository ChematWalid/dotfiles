//! D-Bus connection and signal listener for MPRIS media players.

use crate::state::{query_current_state, MediaState};
use anyhow::{Context, Result};
use futures_lite::StreamExt;
use std::collections::HashMap;
use tokio::sync::watch;
use zbus::{message::Type as MsgType, Connection, MatchRule, Message, MessageStream, OwnedVariant};

fn affects_displayed_state(message: &Message) -> bool {
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

pub async fn start_dbus_listener(state: watch::Sender<MediaState>) -> Result<()> {
    let conn = Connection::session()
        .await
        .context("Failed to connect to D-Bus session bus")?;

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

    let mut props_stream = MessageStream::for_match_rule(props_rule, &conn, None).await?;
    let mut name_stream = MessageStream::for_match_rule(name_rule, &conn, None).await?;

    tokio::spawn(async move {
        loop {
            tokio::select! {
                Some(msg_result) = props_stream.next() => {
                    if msg_result.as_ref().map_or(true, affects_displayed_state) {
                        let latest = query_current_state().await;
                        state.send_replace(latest);
                    }
                }
                Some(msg_result) = name_stream.next() => {
                    if let Ok(msg) = msg_result {
                        let body: Result<(String, String, String), _> = msg.body().deserialize();
                        if let Ok((name, _old, _new)) = body {
                            if name.starts_with("org.mpris.") {
                                let latest = query_current_state().await;
                                state.send_replace(latest);
                            }
                        }
                    }
                }
            }
        }
    });

    Ok(())
}
