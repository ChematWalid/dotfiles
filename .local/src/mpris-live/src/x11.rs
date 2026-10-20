//! X11 root window PointerMotion listener using x11rb.
//! Event-driven hover detection: zero polling, zero idle CPU.

use crate::config::{HOVER_X_MAX, HOVER_X_MIN, HOVER_Y_MIN};
use std::thread;
use std::time::Duration;
use tokio::sync::watch;
use x11rb::connection::Connection as X11Connection;
use x11rb::protocol::xproto::{ChangeWindowAttributesAux, ConnectionExt, EventMask};
use x11rb::protocol::Event as X11Event;

const INITIAL_BACKOFF: Duration = Duration::from_millis(500);
const MAX_BACKOFF: Duration = Duration::from_secs(10);

#[inline]
pub fn is_hovering(x: i16, y: i16) -> bool {
    y >= HOVER_Y_MIN && (HOVER_X_MIN..=HOVER_X_MAX).contains(&x)
}

pub fn spawn_hover_thread(hover_tx: watch::Sender<bool>) {
    thread::spawn(move || {
        let mut backoff = INITIAL_BACKOFF;

        while !hover_tx.is_closed() {
            let (conn, screen_num) = match x11rb::connect(None) {
                Ok(res) => res,
                Err(_) => {
                    let _ = hover_tx.send(false);
                    if hover_tx.is_closed() {
                        return;
                    }
                    thread::sleep(backoff);
                    backoff = (backoff * 2).min(MAX_BACKOFF);
                    continue;
                }
            };

            let screen = match conn.setup().roots.get(screen_num) {
                Some(s) => s,
                None => {
                    let _ = hover_tx.send(false);
                    if hover_tx.is_closed() {
                        return;
                    }
                    thread::sleep(backoff);
                    backoff = (backoff * 2).min(MAX_BACKOFF);
                    continue;
                }
            };
            let root = screen.root;

            // Subscribe to pointer motion on the root window
            if conn
                .change_window_attributes(
                    root,
                    &ChangeWindowAttributesAux::new().event_mask(EventMask::POINTER_MOTION),
                )
                .is_err()
                || conn.flush().is_err()
            {
                let _ = hover_tx.send(false);
                if hover_tx.is_closed() {
                    return;
                }
                thread::sleep(backoff);
                backoff = (backoff * 2).min(MAX_BACKOFF);
                continue;
            }

            // Successfully connected and subscribed to X11 pointer motion
            backoff = INITIAL_BACKOFF;

            let mut last_hovering = conn
                .query_pointer(root)
                .ok()
                .and_then(|cookie| cookie.reply().ok())
                .map(|pointer| is_hovering(pointer.root_x, pointer.root_y))
                .unwrap_or(false);

            if hover_tx.send(last_hovering).is_err() {
                return;
            }

            loop {
                match conn.wait_for_event() {
                    Ok(X11Event::MotionNotify(ev)) => {
                        let is_hover = is_hovering(ev.root_x, ev.root_y);
                        if last_hovering != is_hover {
                            if hover_tx.send(is_hover).is_err() {
                                return;
                            }
                            last_hovering = is_hover;
                        }
                    }
                    Err(_) => {
                        // X11 connection lost or event error, reset hover state and reconnect
                        let _ = hover_tx.send(false);
                        break;
                    }
                    _ => {}
                }
            }

            if hover_tx.is_closed() {
                return;
            }
            thread::sleep(backoff);
            backoff = (backoff * 2).min(MAX_BACKOFF);
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_hovering_within_bounds() {
        assert!(is_hovering(400, 720));
        assert!(is_hovering(660, 750));
        assert!(is_hovering(920, 768));
    }

    #[test]
    fn test_is_hovering_outside_bounds() {
        assert!(!is_hovering(399, 720));
        assert!(!is_hovering(921, 720));
        assert!(!is_hovering(660, 719));
        assert!(!is_hovering(0, 0));
    }

    #[test]
    fn test_spawn_hover_thread_graceful_shutdown() {
        let (hover_tx, hover_rx) = watch::channel(false);
        spawn_hover_thread(hover_tx);
        // Immediately drop receiver to trigger shutdown
        drop(hover_rx);
    }
}
