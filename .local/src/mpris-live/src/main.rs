//! mpris-live — Real-time Polybar MPRIS module + Conky desktop synchronizer.
//! Zero polling, event-driven architecture using zbus 5 and x11rb.

mod config;
mod dbus;
mod instance;
mod render;
mod state;
mod x11;

use anyhow::Result;
use std::io::{stdout, Write};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{interval, Duration};

use config::{MAX_CHARS, SCROLL_MS, SEPARATOR};
use state::{query_current_state, write_conky};

#[tokio::main]
async fn main() -> Result<()> {
    instance::ensure_single_instance();

    let current = query_current_state();
    write_conky(&current.status, &current.full_text);

    let state = Arc::new(Mutex::new(current));
    let hovering = Arc::new(AtomicBool::new(false));
    let mouse_x = Arc::new(AtomicI32::new(0));
    let mouse_y = Arc::new(AtomicI32::new(0));

    // Spawn X11 motion thread for zero-polling mouse hover detection
    x11::spawn_hover_thread(
        Arc::clone(&hovering),
        Arc::clone(&mouse_x),
        Arc::clone(&mouse_y),
    );

    // Start D-Bus event stream for real-time player status updates
    dbus::start_dbus_listener(Arc::clone(&state)).await?;

    // Main render loop for Polybar stdout
    let mut scroll_pos: usize = 0;
    let mut last_rendered: String = String::new();
    let mut last_text: String = String::new();
    let mut ticker = interval(Duration::from_millis(SCROLL_MS));

    loop {
        ticker.tick().await;
        let is_h = hovering.load(Ordering::Relaxed);

        let current_state = {
            let st = state.lock().await;
            st.clone()
        };

        if current_state.full_text != last_text {
            scroll_pos = 0;
            last_text = current_state.full_text.clone();
        }

        let rendered = render::render_polybar(&current_state, scroll_pos, is_h);

        if rendered != last_rendered {
            println!("{}", rendered);
            let _ = stdout().flush();
            last_rendered = rendered;
        }

        // Only tick scroll when mouse is hovering and text exceeds MAX_CHARS
        let char_len = current_state.full_text.chars().count();
        if is_h && char_len > MAX_CHARS {
            let stream_len = char_len + SEPARATOR.chars().count();
            scroll_pos = (scroll_pos + 1) % stream_len;
        } else if !is_h {
            scroll_pos = 0;
        }
    }
}
