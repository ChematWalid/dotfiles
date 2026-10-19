//! desktop-music-daemon — Real-time MPRIS D-Bus event daemon for Conky desktop.
//! Zero polling, event-driven architecture using zbus 5.

mod config;
mod mpris;
mod writer;

use anyhow::{Context, Result};
use futures_lite::StreamExt;
use zbus::Connection;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    // Write initial state immediately
    let mut output = writer::OutputWriter::new().context("initialize Conky music output")?;
    report_write_error(output.write(&mpris::query_current_state().await));

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
            Some(msg_result) = props_stream.next() => {
                if msg_result.as_ref().map_or(true, mpris::affects_displayed_state) {
                    report_write_error(output.write(&mpris::query_current_state().await));
                }
            }
            // A D-Bus name appeared or disappeared
            Some(msg_result) = name_stream.next() => {
                if let Ok(msg) = msg_result {
                    let body: Result<(String, String, String), _> = msg.body().deserialize();
                    if let Ok((name, _old, _new)) = body {
                        if name.starts_with("org.mpris.") {
                            report_write_error(output.write(&mpris::query_current_state().await));
                        }
                    }
                }
            }
        }
    }
}

fn report_write_error(result: Result<()>) {
    if let Err(error) = result {
        eprintln!("desktop-music-daemon: could not update Conky music output: {error}");
    }
}
