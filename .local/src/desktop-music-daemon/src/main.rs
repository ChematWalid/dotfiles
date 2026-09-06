//! desktop-music-daemon — Real-time MPRIS music display daemon for desktop.
//! Converted from Python to Rust for sub-millisecond latency and minimal memory.

use anyhow::{Context, Result};
use futures_lite::stream::StreamExt;
use std::collections::HashMap;
use std::fs;
use std::ops::Deref;
use std::process::{self, Command};
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::time::{Duration, interval};
use zbus::fdo::{DBusProxy, PropertiesProxy};
use zbus::zvariant::{OwnedValue, Value};
use zbus::{Connection, Message};

const OUTPUT_FILE: &str = "/tmp/conky-music.txt";
const TMP_FILE: &str = "/tmp/conky-music.txt.tmp";
const PID_FILE: &str = "/tmp/.desktop-music-daemon.pid";
const MPRIS_PREFIX: &str = "org.mpris.MediaPlayer2.";
const MPRIS_PATH: &str = "/org/mpris/MediaPlayer2";
const MPRIS_PLAYER_IFACE: &str = "org.mpris.MediaPlayer2.Player";

#[derive(Debug, Clone, Default)]
struct PlayerInfo {
    status: String, // "Playing" | "Paused" | "Stopped"
    artist: String,
    title: String,
}

struct State {
    players: HashMap<String, PlayerInfo>,
    current_text: String,
}

impl State {
    fn new() -> Self {
        State {
            players: HashMap::new(),
            current_text: String::new(),
        }
    }

    fn update_output(&mut self) {
        let text = self.compute_text();
        if text == self.current_text {
            return;
        }
        self.current_text = text.clone();
        write_output_atomic(&text);
    }

    fn compute_text(&self) -> String {
        // Prefer Playing player
        let active = self
            .players
            .values()
            .find(|p| p.status == "Playing" && (!p.title.is_empty() || !p.artist.is_empty()))
            .or_else(|| {
                // Fallback to Paused player
                self.players
                    .values()
                    .find(|p| p.status == "Paused" && (!p.title.is_empty() || !p.artist.is_empty()))
            });

        if let Some(p) = active {
            let icon = if p.status == "Playing" {
                "󰐊 "
            } else {
                "󰏤 "
            };
            if !p.artist.is_empty() && !p.title.is_empty() {
                return format!("{}{} - {}", icon, p.artist, p.title);
            } else {
                return format!("{}{}", icon, if p.title.is_empty() { &p.artist } else { &p.title });
            }
        }

        // Fallback: check mpc current
        if let Ok(out) = Command::new("mpc")
            .arg("current")
            .stderr(process::Stdio::null())
            .output()
        {
            let mpc = String::from_utf8_lossy(&out.stdout).trim().to_string();
            if !mpc.is_empty() {
                return format!("󰐊 {}", mpc);
            }
        }

        String::new()
    }
}

fn extract_meta(v: &OwnedValue) -> (String, String) {
    let mut artist = String::new();
    let mut title = String::new();

    if let Value::Dict(dict) = v.deref() {
        for (k, val) in dict.iter() {
            if let Value::Str(key_str) = k {
                match key_str.as_str() {
                    "xesam:artist" => {
                        match val {
                            Value::Array(arr) => {
                                if let Some(Value::Str(s)) = arr.iter().next() {
                                    artist = s.as_str().to_string();
                                }
                            }
                            Value::Str(s) => artist = s.as_str().to_string(),
                            _ => {}
                        }
                    }
                    "xesam:title" => {
                        if let Value::Str(s) = val {
                            title = s.as_str().to_string();
                        }
                    }
                    _ => {}
                }
            }
        }
    }
    (artist, title)
}

fn write_output_atomic(text: &str) {
    let _ = fs::write(TMP_FILE, text.trim())
        .and_then(|_| fs::rename(TMP_FILE, OUTPUT_FILE));
}

fn ensure_single_instance() {
    let my_pid = process::id();
    if let Ok(contents) = fs::read_to_string(PID_FILE) {
        if let Ok(old_pid) = contents.trim().parse::<u32>() {
            if old_pid != my_pid {
                let _ = Command::new("kill")
                    .args(["-9", &old_pid.to_string()])
                    .output();
            }
        }
    }
    let _ = fs::write(PID_FILE, my_pid.to_string());
}

async fn read_player_props(conn: &Connection, bus_name: &str) -> Option<PlayerInfo> {
    let proxy = PropertiesProxy::builder(conn)
        .destination(bus_name.to_string()).ok()?
        .path(MPRIS_PATH).ok()?
        .build()
        .await
        .ok()?;

    let iface = MPRIS_PLAYER_IFACE.try_into().ok()?;
    let props: HashMap<String, OwnedValue> = proxy.get_all(iface).await.ok()?;

    let status = props
        .get("PlaybackStatus")
        .and_then(|v| {
            if let Value::Str(s) = v.deref() {
                Some(s.as_str().to_string())
            } else {
                None
            }
        })
        .unwrap_or_else(|| "Stopped".to_string());

    let (artist, title) = props
        .get("Metadata")
        .map(extract_meta)
        .unwrap_or_default();

    Some(PlayerInfo { status, artist, title })
}

async fn list_mpris_players(conn: &Connection) -> Result<Vec<String>> {
    let dbus_proxy = DBusProxy::new(conn).await?;
    let names = dbus_proxy.list_names().await?;
    Ok(names
        .into_iter()
        .filter(|n| n.starts_with(MPRIS_PREFIX))
        .map(|n| n.to_string())
        .collect())
}

#[tokio::main]
async fn main() -> Result<()> {
    ensure_single_instance();

    let conn = Connection::session().await.context("connect to session bus")?;
    let state = Arc::new(Mutex::new(State::new()));

    // Initial scan
    {
        let mut st = state.lock().await;
        for name in list_mpris_players(&conn).await.unwrap_or_default() {
            if let Some(info) = read_player_props(&conn, &name).await {
                st.players.insert(name, info);
            }
        }
        st.update_output();
    }

    // Subscribe to PropertiesChanged on MPRIS path
    let props_rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus.Properties")?
        .member("PropertiesChanged")?
        .path(MPRIS_PATH)?
        .build();

    let mut props_stream = zbus::MessageStream::for_match_rule(props_rule, &conn, None)
        .await
        .context("subscribe PropertiesChanged")?;

    // Subscribe to NameOwnerChanged
    let noc_rule = zbus::MatchRule::builder()
        .msg_type(zbus::message::Type::Signal)
        .interface("org.freedesktop.DBus")?
        .member("NameOwnerChanged")?
        .build();

    let mut noc_stream = zbus::MessageStream::for_match_rule(noc_rule, &conn, None)
        .await
        .context("subscribe NameOwnerChanged")?;

    // Periodic sync every 2 seconds
    let conn_periodic = conn.clone();
    let state_periodic = Arc::clone(&state);
    tokio::spawn(async move {
        let mut ticker = interval(Duration::from_secs(2));
        loop {
            ticker.tick().await;
            let names = list_mpris_players(&conn_periodic).await.unwrap_or_default();
            let mut st = state_periodic.lock().await;
            st.players.retain(|k, _| names.contains(k));
            for name in &names {
                if let Some(info) = read_player_props(&conn_periodic, name).await {
                    st.players.insert(name.clone(), info);
                }
            }
            st.update_output();
        }
    });

    // Event loop
    loop {
        tokio::select! {
            Some(Ok(msg)) = props_stream.next() => {
                handle_properties_changed(&conn, Arc::clone(&state), msg).await;
            }
            Some(Ok(msg)) = noc_stream.next() => {
                handle_name_owner_changed(&conn, Arc::clone(&state), msg).await;
            }
            else => break,
        }
    }

    Ok(())
}

async fn handle_properties_changed(
    conn: &Connection,
    state: Arc<Mutex<State>>,
    msg: Message,
) {
    let Ok((iface, changed, _)) = msg.body().deserialize::<(String, HashMap<String, OwnedValue>, Vec<String>)>() else {
        return;
    };
    if iface != MPRIS_PLAYER_IFACE {
        return;
    }

    let sender = msg.header().sender().map(|s| s.to_string()).unwrap_or_default();
    let bus_name = {
        let names = list_mpris_players(conn).await.unwrap_or_default();
        let dbus_proxy = DBusProxy::new(conn).await.ok();
        let mut found = sender.clone();
        if let Some(proxy) = dbus_proxy {
            for name in &names {
                if let Ok(owner_target) = name.as_str().try_into() {
                    if let Ok(owner) = proxy.get_name_owner(owner_target).await {
                        if owner.as_str() == sender {
                            found = name.clone();
                            break;
                        }
                    }
                }
            }
        }
        found
    };

    let mut st = state.lock().await;
    let entry = st.players.entry(bus_name).or_default();

    if let Some(v) = changed.get("PlaybackStatus") {
        if let Value::Str(s) = v.deref() {
            entry.status = s.as_str().to_string();
        }
    }

    if let Some(meta_val) = changed.get("Metadata") {
        let (artist, title) = extract_meta(meta_val);
        entry.artist = artist;
        entry.title = title;
    }

    st.update_output();
}

async fn handle_name_owner_changed(
    conn: &Connection,
    state: Arc<Mutex<State>>,
    msg: Message,
) {
    let Ok((name, old_owner, new_owner)) = msg.body().deserialize::<(String, String, String)>() else {
        return;
    };
    if !name.starts_with(MPRIS_PREFIX) {
        return;
    }

    let mut st = state.lock().await;
    if new_owner.is_empty() {
        st.players.remove(&name);
        st.players.remove(&old_owner);
        st.update_output();
    } else {
        drop(st);
        if let Some(info) = read_player_props(conn, &name).await {
            let mut st2 = state.lock().await;
            st2.players.insert(name, info);
            st2.update_output();
        }
    }
}
