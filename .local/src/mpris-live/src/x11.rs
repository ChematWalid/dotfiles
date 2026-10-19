//! X11 root window PointerMotion listener using x11rb.
//! Event-driven hover detection: zero polling, zero idle CPU.

use crate::config::{HOVER_X_MAX, HOVER_X_MIN, HOVER_Y_MIN};
use std::thread;
use tokio::sync::watch;
use x11rb::connection::Connection as X11Connection;
use x11rb::protocol::xproto::{ChangeWindowAttributesAux, ConnectionExt, EventMask};
use x11rb::protocol::Event as X11Event;

pub fn spawn_hover_thread(hover_tx: watch::Sender<bool>) {
    thread::spawn(move || {
        let Ok((conn, screen_num)) = x11rb::connect(None) else {
            return;
        };
        let screen = &conn.setup().roots[screen_num];
        let root = screen.root;

        // Subscribe to pointer motion on the root window
        let _ = conn.change_window_attributes(
            root,
            &ChangeWindowAttributesAux::new().event_mask(EventMask::POINTER_MOTION),
        );
        let _ = conn.flush();

        let mut last_hovering = conn
            .query_pointer(root)
            .ok()
            .and_then(|cookie| cookie.reply().ok())
            .map(|pointer| {
                pointer.root_y >= HOVER_Y_MIN
                    && (HOVER_X_MIN..=HOVER_X_MAX).contains(&pointer.root_x)
            });
        if let Some(is_hovering) = last_hovering {
            let _ = hover_tx.send(is_hovering);
        }

        loop {
            match conn.wait_for_event() {
                Ok(X11Event::MotionNotify(ev)) => {
                    let x = ev.root_x;
                    let y = ev.root_y;
                    let is_hover = y >= HOVER_Y_MIN && (HOVER_X_MIN..=HOVER_X_MAX).contains(&x);
                    if last_hovering != Some(is_hover) {
                        if hover_tx.send(is_hover).is_err() {
                            break;
                        }
                        last_hovering = Some(is_hover);
                    }
                }
                Err(_) => break,
                _ => {}
            }
        }
    });
}
