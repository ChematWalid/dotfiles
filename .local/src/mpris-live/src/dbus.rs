//! D-Bus connection and signal listener for MPRIS media players.

use crate::state::{query_current_state, write_conky, MediaState};
use anyhow::{Context, Result};
use futures_lite::StreamExt;
use std::sync::Arc;
use tokio::sync::Mutex;
use zbus::{message::Type as MsgType, Connection, MatchRule, MessageStream};

pub async fn start_dbus_listener(state: Arc<Mutex<MediaState>>) -> Result<()> {
    let conn = Connection::session()
        .await
        .context("Failed to connect to D-Bus session bus")?;

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

    let mut props_stream = MessageStream::for_match_rule(props_rule, &conn, None).await?;
    let mut name_stream = MessageStream::for_match_rule(name_rule, &conn, None).await?;

    tokio::spawn(async move {
        loop {
            tokio::select! {
                Some(_) = props_stream.next() => {
                    let latest = query_current_state();
                    write_conky(&latest.status, &latest.full_text);
                    *state.lock().await = latest;
                }
                Some(msg_result) = name_stream.next() => {
                    if let Ok(msg) = msg_result {
                        let body: Result<(String, String, String), _> = msg.body().deserialize();
                        if let Ok((name, _old, _new)) = body {
                            if name.starts_with("org.mpris.") {
                                let latest = query_current_state();
                                write_conky(&latest.status, &latest.full_text);
                                *state.lock().await = latest;
                            }
                        }
                    }
                }
            }
        }
    });

    Ok(())
}
