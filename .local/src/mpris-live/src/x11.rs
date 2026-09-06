//! X11 root window PointerMotion listener using x11rb.
//! Event-driven hover detection: zero polling, zero idle CPU.

use crate::config::{HOVER_X_MAX, HOVER_X_MIN, HOVER_Y_MIN};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::Arc;
use std::thread;
use x11rb::connection::Connection as X11Connection;
use x11rb::protocol::xproto::{ChangeWindowAttributesAux, ConnectionExt, EventMask};
use x11rb::protocol::Event as X11Event;

pub fn spawn_hover_thread(
    hovering: Arc<AtomicBool>,
    mouse_x: Arc<AtomicI32>,
    mouse_y: Arc<AtomicI32>,
) {
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

        loop {
            match conn.wait_for_event() {
                Ok(X11Event::MotionNotify(ev)) => {
                    let x = ev.root_x;
                    let y = ev.root_y;
                    mouse_x.store(x as i32, Ordering::Relaxed);
                    mouse_y.store(y as i32, Ordering::Relaxed);
                    let is_hover = y >= HOVER_Y_MIN && (HOVER_X_MIN..=HOVER_X_MAX).contains(&x);
                    hovering.store(is_hover, Ordering::Relaxed);
                }
                Err(_) => break,
                _ => {}
            }
        }
    });
}
