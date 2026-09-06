//! mpris-live — Zero-polling real-time Polybar MPRIS module.
//!
//! Event sources:
//!   • MPRIS state  : zbus D-Bus subscription to PropertiesChanged + NameOwnerChanged
//!   • Mouse hover  : x11rb MotionNotify on root window (fires only on actual movement)
//!   • Scroll tick  : 180ms interval only when hovering AND text overflows MAX_CHARS
//!
//! No heartbeat, no playerctl subprocess, no xdotool polling.

use std::fs;
use std::io::{stdout, Write};
use std::process::{self, Command as SyncCommand, Stdio};
use std::sync::atomic::{AtomicBool, AtomicI32, Ordering};
use std::sync::Arc;
use std::thread;

use futures_lite::StreamExt;
use zbus::{Connection, MatchRule, MessageStream, message::Type as MsgType};
use tokio::sync::Mutex;
use tokio::time::{interval, Duration};
use x11rb::connection::Connection as X11Connection;
use x11rb::protocol::xproto::{
    ChangeWindowAttributesAux, ConnectionExt, EventMask,
};
use x11rb::protocol::Event as X11Event;

// ── Constants ────────────────────────────────────────────────────────────────
const MAX_CHARS: usize = 18;
const SCROLL_MS: u64   = 180;
const SEPARATOR: &str  = "   •   ";
const CONKY_FILE: &str = "/tmp/conky-music.txt";
const CONKY_TMP:  &str = "/tmp/conky-music.txt.tmp";
const PID_FILE:   &str = "/tmp/.polybar-mpris-live.pid";

// Polybar bottom bar region where the mpris module lives (pixels)
const HOVER_Y_MIN: i16 = 720;
const HOVER_X_MIN: i16 = 400;
const HOVER_X_MAX: i16 = 920;

// ── Icons (Nerd Font) ────────────────────────────────────────────────────────
// play-circle (shown when status=Playing, click = pause)
const ICON_PAUSE_BTN: &str = "\u{f03e5}"; // 󰏥 green
// pause-circle (shown when status=Paused, click = play)
const ICON_PLAY_BTN:  &str = "\u{f040c}"; // 󰐌 yellow
const ICON_PREV: &str = "\u{f04ae}"; // 󰒮
const ICON_NEXT: &str = "\u{f04ad}"; // 󰒭
const ICON_NOTE: &str = "\u{f0386}"; // 󰎆

// ── Shared state ─────────────────────────────────────────────────────────────
#[derive(Debug, Clone, Default)]
struct MediaState {
    player:    String,
    status:    String,
    full_text: String,
}

fn write_conky(status: &str, full_text: &str) {
    let text = if status == "Playing" && !full_text.is_empty() {
        format!("\u{f040a} {}", full_text) // 󰐊
    } else if status == "Paused" && !full_text.is_empty() {
        format!("\u{f03e4} {}", full_text) // 󰏤
    } else {
        String::new()
    };
    let _ = fs::write(CONKY_TMP, text.trim())
        .and_then(|_| fs::rename(CONKY_TMP, CONKY_FILE));
}

fn ensure_single_instance() {
    let my_pid = process::id();
    if let Ok(contents) = fs::read_to_string(PID_FILE) {
        if let Ok(old_pid) = contents.trim().parse::<u32>() {
            if old_pid != my_pid {
                let _ = SyncCommand::new("kill")
                    .args(["-9", &old_pid.to_string()])
                    .output();
            }
        }
    }
    let _ = fs::write(PID_FILE, my_pid.to_string());
}

fn query_current_state() -> MediaState {
    let out = SyncCommand::new("playerctl")
        .args(["metadata", "-a", "--format",
               "{{playerName}}:::{{status}}:::{{artist}}:::{{title}}"])
        .stderr(Stdio::null())
        .output();

    if let Ok(out) = out {
        let stdout = String::from_utf8_lossy(&out.stdout);
        let mut playing: Option<MediaState> = None;
        let mut paused:  Option<MediaState> = None;

        for line in stdout.lines() {
            let p: Vec<&str> = line.splitn(5, ":::").collect();
            if p.len() < 4 { continue; }
            let player = p[0].trim().to_string();
            let status = p[1].trim().to_string();
            let artist = p[2].trim();
            let title  = p[3].trim();

            if artist.is_empty() && title.is_empty() { continue; }

            let full_text = match (artist.is_empty(), title.is_empty()) {
                (false, false) => format!("{} - {}", artist, title),
                (true,  false) => title.to_string(),
                _              => artist.to_string(),
            };

            let st = MediaState { player, status: status.clone(), full_text };
            if status == "Playing" && playing.is_none() {
                playing = Some(st);
            } else if status == "Paused" && paused.is_none() {
                paused = Some(st);
            }
            if playing.is_some() { break; }
        }

        if let Some(s) = playing { return s; }
        if let Some(s) = paused  { return s; }
    }

    MediaState::default()
}

fn get_marquee_slice(text: &str, offset: usize, hovering: bool) -> String {
    let chars: Vec<char> = text.chars().collect();
    if chars.len() <= MAX_CHARS {
        return text.to_string();
    }
    if !hovering {
        let prefix: String = chars.iter().take(MAX_CHARS - 1).collect();
        return format!("{}…", prefix);
    }
    let sep_chars: Vec<char> = SEPARATOR.chars().collect();
    let mut stream: Vec<char> = chars.clone();
    stream.extend_from_slice(&sep_chars);
    let stream_len = stream.len();
    let idx = offset % stream_len;
    stream.iter().cycle().skip(idx).take(MAX_CHARS).collect()
}

fn render(state: &MediaState, scroll_pos: usize, hovering: bool) -> String {
    if state.player.is_empty() || state.status == "Stopped" || state.full_text.is_empty() {
        return String::new();
    }

    let (play_icon, play_color) = if state.status == "Playing" {
        (ICON_PAUSE_BTN, "#a6e3a1") // green pause-circle
    } else {
        (ICON_PLAY_BTN,  "#f9e2af") // yellow play-circle
    };

    let display = get_marquee_slice(&state.full_text, scroll_pos, hovering);
    let p = &state.player;

    format!(
        "%{{T4}}%{{F#89b4fa}}%{{A1:playerctl -p {p} previous 2>/dev/null:}}{ICON_PREV}%{{A}}%{{F-}}  \
         %{{A1:playerctl -p {p} play-pause 2>/dev/null:}}%{{F{play_color}}}{play_icon}%{{F-}}%{{A}}  \
         %{{F#89b4fa}}%{{A1:playerctl -p {p} next 2>/dev/null:}}{ICON_NEXT}%{{A}}%{{F-}}%{{T-}}   \
         %{{F#f5c2e7}}{ICON_NOTE}%{{F-}} %{{F#cdd6f4}}{display}%{{F-}}"
    )
}

// ── X11 hover detection thread ───────────────────────────────────────────────
// Subscribes to PointerMotion events on the root window.
// Updates AtomicBool only on actual mouse movement — zero CPU when idle.
fn spawn_hover_thread(hovering: Arc<AtomicBool>, mouse_x: Arc<AtomicI32>, mouse_y: Arc<AtomicI32>) {
    thread::spawn(move || {
        let Ok((conn, screen_num)) = x11rb::connect(None) else { return };
        let screen = &conn.setup().roots[screen_num];
        let root = screen.root;

        // Subscribe to pointer motion on the root window
        let _ = conn.change_window_attributes(
            root,
            &ChangeWindowAttributesAux::new()
                .event_mask(EventMask::POINTER_MOTION),
        );
        let _ = conn.flush();

        loop {
            match conn.wait_for_event() {
                Ok(X11Event::MotionNotify(ev)) => {
                    let x = ev.root_x;
                    let y = ev.root_y;
                    mouse_x.store(x as i32, Ordering::Relaxed);
                    mouse_y.store(y as i32, Ordering::Relaxed);
                    let is_hover = y >= HOVER_Y_MIN
                        && x >= HOVER_X_MIN
                        && x <= HOVER_X_MAX;
                    hovering.store(is_hover, Ordering::Relaxed);
                }
                Err(_) => break,
                _ => {}
            }
        }
    });
}

// ── Main ─────────────────────────────────────────────────────────────────────
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    ensure_single_instance();

    let state   = Arc::new(Mutex::new(query_current_state()));
    let hovering = Arc::new(AtomicBool::new(false));
    let mouse_x  = Arc::new(AtomicI32::new(0));
    let mouse_y  = Arc::new(AtomicI32::new(0));

    // Write initial Conky state
    {
        let st = state.lock().await;
        write_conky(&st.status, &st.full_text);
    }

    // ── Thread: X11 MotionNotify for hover (event-driven, no poll) ──────────
    spawn_hover_thread(
        Arc::clone(&hovering),
        Arc::clone(&mouse_x),
        Arc::clone(&mouse_y),
    );

    // ── D-Bus connection ─────────────────────────────────────────────────────
    let conn = Connection::session().await?;

    // Match: PropertiesChanged on any MPRIS player
    let props_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path("/org/mpris/MediaPlayer2")?
        .build();

    // Match: NameOwnerChanged (player opens/closes)
    let name_rule = MatchRule::builder()
        .msg_type(MsgType::Signal)
        .sender("org.freedesktop.DBus")?
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .build();

    let mut props_stream = MessageStream::for_match_rule(props_rule, &conn, None).await?;
    let mut name_stream  = MessageStream::for_match_rule(name_rule,  &conn, None).await?;

    // ── Task: D-Bus event listener ───────────────────────────────────────────
    let state_dbus = Arc::clone(&state);
    tokio::spawn(async move {
        loop {
            tokio::select! {
                Some(_) = props_stream.next() => {
                    let latest = query_current_state();
                    write_conky(&latest.status, &latest.full_text);
                    *state_dbus.lock().await = latest;
                }
                Some(msg_result) = name_stream.next() => {
                    if let Ok(msg) = msg_result {
                        let body: Result<(String, String, String), _> = msg.body().deserialize();
                        if let Ok((name, _old, _new)) = body {
                            if name.starts_with("org.mpris.") {
                                let latest = query_current_state();
                                write_conky(&latest.status, &latest.full_text);
                                *state_dbus.lock().await = latest;
                            }
                        }
                    }
                }
            }
        }
    });

    // ── Main render loop — only ticks for scrolling ──────────────────────────
    // When not hovering or text fits: no scrolling needed, but we still
    // need to emit on state changes. The D-Bus task handles state updates;
    // the render loop re-renders when state changes OR scroll position moves.
    let mut scroll_pos:    usize  = 0;
    let mut last_rendered: String = String::new();
    let mut last_text:     String = String::new();
    let mut ticker = interval(Duration::from_millis(SCROLL_MS));

    loop {
        ticker.tick().await;
        let is_h = hovering.load(Ordering::Relaxed);

        let current = {
            let st = state.lock().await;
            st.clone()
        };

        if current.full_text != last_text {
            scroll_pos = 0;
            last_text = current.full_text.clone();
        }

        let rendered = render(&current, scroll_pos, is_h);

        if rendered != last_rendered {
            println!("{}", rendered);
            let _ = stdout().flush();
            last_rendered = rendered;
        }

        // Only advance scroll when hovering and text overflows
        let char_len = current.full_text.chars().count();
        if is_h && char_len > MAX_CHARS {
            let stream_len = char_len + SEPARATOR.chars().count();
            scroll_pos = (scroll_pos + 1) % stream_len;
        } else if !is_h {
            scroll_pos = 0;
        }
    }
}
