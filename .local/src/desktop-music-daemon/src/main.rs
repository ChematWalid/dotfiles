//! desktop-music-daemon — Real-time MPRIS D-Bus event daemon for Conky desktop.
//! Zero polling, event-driven architecture using zbus 5.

mod config;
mod instance;
mod mpris;
mod writer;

use anyhow::{Context, Result};
use futures_lite::StreamExt;
use zbus::Connection;

#[tokio::main]
async fn main() -> Result<()> {
    instance::ensure_single_instance();

    // Write initial state immediately
    writer::write_output_atomic(&mpris::query_current_state());

    // Connect to session D-Bus
    let conn = Connection::session()
        .await
        .context("Failed to connect to D-Bus session bus")?;

    let (mut props_stream, mut name_stream) = mpris::setup_dbus_streams(&conn)
        .await
        .context("Failed to setup D-Bus match streams")?;

    loop {
        tokio::select! {
            // MPRIS playback status or track property changed
            Some(_) = props_stream.next() => {
                writer::write_output_atomic(&mpris::query_current_state());
            }
            // A D-Bus name appeared or disappeared
            Some(msg_result) = name_stream.next() => {
                if let Ok(msg) = msg_result {
                    let body: Result<(String, String, String), _> = msg.body().deserialize();
                    if let Ok((name, _old, _new)) = body {
                        if name.starts_with("org.mpris.") {
                            writer::write_output_atomic(&mpris::query_current_state());
                        }
                    }
                }
            }
        }
    }
}
