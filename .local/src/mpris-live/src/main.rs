//! mpris-live — Real-time MPRIS status module for Polybar.
//! Zero polling, event-driven architecture using zbus 5 and x11rb.

mod bidi;
mod config;
mod dbus;
mod render;
mod state;
mod x11;

use anyhow::Result;
use std::io::{stdout, Write};
use tokio::sync::watch;
use tokio::time::{interval, Duration, MissedTickBehavior};

use config::{MAX_CHARS, SCROLL_MS, SEPARATOR};
use state::MediaState;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<()> {
    // The listener queries current MPRIS state after installing its D-Bus
    // match rules, avoiding a redundant playerctl process and the startup race.
    let (state_tx, mut state_rx) = watch::channel(MediaState::default());
    let (hover_tx, mut hover_rx) = watch::channel(false);

    // Keep the listener alive if the X11 connection cannot be established.
    let _hover_guard = hover_tx.clone();
    x11::spawn_hover_thread(hover_tx);

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
            let text_len = current_state.full_text_chars;
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
            changed = hover_rx.changed() => {
                if changed.is_err() {
                    break;
                }
                hovering = *hover_rx.borrow_and_update();
                if !hovering {
                    scroll_pos = 0;
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
