//! mpris-live — Real-time MPRIS status module for Polybar.
//! Zero polling, event-driven architecture using zbus 5 and x11rb.

mod config;
mod dbus;
mod render;
mod state;
mod x11;

use anyhow::Result;
use std::io::{stdout, Write};
use tokio::sync::{mpsc, watch};
use tokio::time::{interval, Duration, MissedTickBehavior};

use config::{MAX_CHARS, SCROLL_MS, SEPARATOR};
use state::query_current_state;

enum UiEvent {
    HoverChanged(bool),
}

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    let current = query_current_state().await;

    let (state_tx, mut state_rx) = watch::channel(current);
    let (event_tx, mut event_rx) = mpsc::unbounded_channel();

    // Keep the channel open if the X11 connection cannot be established.
    let _event_guard = event_tx.clone();
    x11::spawn_hover_thread(event_tx);

    // Start D-Bus event stream for real-time player status updates
    dbus::start_dbus_listener(state_tx).await?;

    // Redraw on media or hover events; tick only while scrolling a long title.
    let mut scroll_pos: usize = 0;
    let mut last_rendered: String = String::new();
    let mut last_text = state_rx.borrow().full_text.clone();
    let mut hovering = false;
    let mut ticker = interval(Duration::from_millis(SCROLL_MS));
    ticker.set_missed_tick_behavior(MissedTickBehavior::Delay);
    ticker.tick().await;

    loop {
        let (should_scroll, stream_len) = {
            let current_state = state_rx.borrow();
            let text_len = current_state.full_text.chars().count();
            (
                hovering && text_len > MAX_CHARS,
                text_len + SEPARATOR.chars().count(),
            )
        };

        tokio::select! {
            changed = state_rx.changed() => {
                if changed.is_err() {
                    break;
                }
            }
            event = event_rx.recv() => {
                match event {
                    Some(UiEvent::HoverChanged(next_hovering)) => {
                        hovering = next_hovering;
                        if !hovering {
                            scroll_pos = 0;
                        }
                    }
                    None => break,
                }
            }
            _ = ticker.tick(), if should_scroll => {
                scroll_pos = (scroll_pos + 1) % stream_len;
            }
        }

        let current_state = state_rx.borrow_and_update();
        if current_state.full_text != last_text {
            scroll_pos = 0;
            last_text.clone_from(&current_state.full_text);
        }

        let rendered = render::render_polybar(&current_state, scroll_pos, hovering);

        if rendered != last_rendered {
            println!("{}", rendered);
            let _ = stdout().flush();
            last_rendered = rendered;
        }
    }

    Ok(())
}
