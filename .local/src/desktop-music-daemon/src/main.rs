//! desktop-music-daemon — Real-time MPRIS D-Bus event daemon for Conky desktop.
//! Zero polling, event-driven architecture using zbus 5.

mod config;
mod mpris;
mod writer;

use anyhow::{anyhow, Context, Result};
use futures_lite::StreamExt;
use zbus::Connection;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    let mut output = writer::OutputWriter::new().context("initialize Conky music output")?;

    // Connect to session D-Bus
    let conn = Connection::session()
        .await
        .context("Failed to connect to D-Bus session bus")?;

    let (mut props_stream, mut name_stream) = mpris::setup_dbus_streams(&conn)
        .await
        .context("Failed to setup D-Bus match streams")?;

    // Re-read after subscribing so a track change during startup cannot be missed.
    report_write_error(output.write(&mpris::query_current_state(&conn).await));

    loop {
        tokio::select! {
            // MPRIS playback status or track property changed
            message = props_stream.next() => {
                match message {
                    Some(Ok(message)) if mpris::affects_displayed_state(&message) => {
                        report_write_error(output.write(&mpris::query_current_state(&conn).await));
                    }
                    Some(Err(error)) => {
                        eprintln!("desktop-music-daemon: D-Bus property stream error: {error}");
                    }
                    Some(Ok(_)) => {}
                    None => return Err(anyhow!("D-Bus property stream ended")),
                }
            }
            // A D-Bus name appeared or disappeared
            message = name_stream.next() => {
                match message {
                    Some(Ok(message)) => {
                        let body: Result<(String, String, String), _> = message.body().deserialize();
                        if let Ok((name, _old, _new)) = body {
                            if name.starts_with("org.mpris.") {
                                report_write_error(output.write(&mpris::query_current_state(&conn).await));
                            }
                        }
                    }
                    Some(Err(error)) => {
                        eprintln!("desktop-music-daemon: D-Bus name stream error: {error}");
                    }
                    None => return Err(anyhow!("D-Bus name stream ended")),
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
