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
        .arg(0, "org.mpris.MediaPlayer2.Player")
        .build()?;

    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")
        .interface("org.freedesktop.DBus")
        .member("NameOwnerChanged")
        .arg0ns("org.mpris")
        .build()?;

    let mut props_stream = MessageStream::for_match_rule(props_rule, &conn, None).await?;
    let mut name_stream = MessageStream::for_match_rule(name_rule, &conn, None).await?;

    // Re-query after the match rules are active to close the startup race.
    state.send_replace(query_current_state(&conn).await);

    tokio::spawn(async move {
        loop {
            tokio::select! {
                message = props_stream.next() => {
                    match message {
                        Some(Ok(message)) if affects_displayed_state(&message) => {
                            let latest = query_current_state(&conn).await;
                            state.send_replace(latest);
                        }
                        Some(Err(error)) => {
                            eprintln!("mpris-live: D-Bus property stream error: {error}");
                        }
                        Some(Ok(_)) => {}
                        None => {
                            eprintln!("mpris-live: D-Bus property stream ended");
                            break;
                        }
                    }
                }
                message = name_stream.next() => {
                    match message {
                        Some(Ok(message)) => {
                            let body: Result<(String, String, String), _> = message.body().deserialize();
                            if let Ok((name, _old, _new)) = body {
                                if name.starts_with("org.mpris.") {
                                    let latest = query_current_state(&conn).await;
                                    state.send_replace(latest);
                                }
                            }
                        }
                        Some(Err(error)) => {
                            eprintln!("mpris-live: D-Bus name stream error: {error}");
                        }
                        None => {
                            eprintln!("mpris-live: D-Bus name stream ended");
                            break;
                        }
                    }
                }
            }
        }
    });

    Ok(())
}
