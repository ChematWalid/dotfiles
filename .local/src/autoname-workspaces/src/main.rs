//! autoname-workspaces — Dynamically updates i3 workspace names with Nerd Font application icons.
//! Converted from Python (i3ipc) to high-performance, native Rust using raw i3 IPC.

use regex::Regex;
use serde_json::Value;
use std::collections::HashMap;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::Duration;

const IGNORE_CLASSES: &[&str] = &[
    "nm-applet",
    "blueman-applet",
    "conky",
    "polybar",
    "i3bar",
    "dunst",
    "notify-osd",
    "slop",
    "xsettingsd",
    "topdock",
    "bottomdock",
    "__i3_scratch",
];

const DEFAULT_ICON: &str = "";

fn build_icon_map() -> HashMap<&'static str, &'static str> {
    let mut m = HashMap::new();
    // Terminals
    m.insert("kitty", "");
    m.insert("alacritty", "");
    m.insert("xterm", "");
    m.insert("urxvt", "");
    m.insert("gnome-terminal", "");
    m.insert("terminator", "");

    // Browsers
    m.insert("google-chrome", "󰊯");
    m.insert("chromium", "󰊯");
    m.insert("firefox", "󰈹");
    m.insert("librewolf", "󰈹");
    m.insert("zen-browser", "󰈹");
    m.insert("brave-browser", "󰊯");

    // Chat & Communication
    m.insert("telegramdesktop", "");
    m.insert("telegram-desktop", "");
    m.insert("telegram", "");
    m.insert("ayugram", "");
    m.insert("64gram", "");
    m.insert("discord", "󰙯");
    m.insert("webcord", "󰙯");
    m.insert("vesktop", "󰙯");
    m.insert("slack", "󰒱");

    // Code, Editors & IDEs
    m.insert("antigravity", "󰘦");
    m.insert("code", "󰨞");
    m.insert("vscodium", "󰨞");
    m.insert("code-oss", "󰨞");
    m.insert("cursor", "󰨞");
    m.insert("jetbrains-idea", "");
    m.insert("jetbrains-pycharm", "");
    m.insert("jetbrains-clion", "");
    m.insert("jetbrains-webstorm", "");
    m.insert("subl", "󰅪");
    m.insert("sublime_text", "󰅪");
    m.insert("emacs", "");
    m.insert("neovim", "");

    // Media & Entertainment
    m.insert("spotify", "");
    m.insert("vlc", "󰕼");
    m.insert("mpv", "󰕼");
    m.insert("gimp", "");
    m.insert("inkscape", "");
    m.insert("obs", "󰑋");
    m.insert("obs-studio", "󰑋");
    m.insert("steam", "󰓓");

    // Utilities & Files
    m.insert("thunar", "");
    m.insert("nautilus", "");
    m.insert("dolphin", "");
    m.insert("pcmanfm", "");
    m.insert("pavucontrol", "󰕾");
    m.insert("blueman-manager", "󰂯");
    m.insert("lxappearance", "󰔎");
    m.insert("postman", "󱂛");
    m.insert("dbeaver", "󰆼");
    m.insert("qbittorrent", "󰇚");

    // Mathematics & Science
    m.insert("kmplot", "");
    m.insert("kig", "");
    m.insert("labplot", "");
    m.insert("cantor", "");
    m.insert("geogebra", "");
    m.insert("maxima", "");
    m.insert("wxmaxima", "");

    m
}

fn get_i3_socket_path() -> String {
    std::env::var("I3SOCK").unwrap_or_else(|_| {
        let out = std::process::Command::new("i3")
            .arg("--get-socketpath")
            .output()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default();
        out
    })
}

struct I3Client {
    sock_path: String,
    stream: Option<UnixStream>,
}

impl I3Client {
    fn new(sock_path: String) -> Self {
        I3Client {
            sock_path,
            stream: None,
        }
    }

    fn ensure_connected(&mut self) -> Result<&mut UnixStream, std::io::Error> {
        if self.stream.is_none() {
            let s = UnixStream::connect(&self.sock_path)?;
            self.stream = Some(s);
        }
        Ok(self.stream.as_mut().unwrap())
    }

    fn send_message(&mut self, msg_type: u32, payload: &str) -> Result<Vec<u8>, std::io::Error> {
        let stream = match self.ensure_connected() {
            Ok(s) => s,
            Err(e) => return Err(e),
        };

        let mut msg = Vec::with_capacity(14 + payload.len());
        msg.extend_from_slice(b"i3-ipc");
        msg.extend_from_slice(&(payload.len() as u32).to_ne_bytes());
        msg.extend_from_slice(&msg_type.to_ne_bytes());
        msg.extend_from_slice(payload.as_bytes());

        if let Err(e) = stream.write_all(&msg) {
            self.stream = None;
            return Err(e);
        }

        let mut header = [0u8; 14];
        if let Err(e) = stream.read_exact(&mut header) {
            self.stream = None;
            return Err(e);
        }

        let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
        let mut body = vec![0u8; len];
        if let Err(e) = stream.read_exact(&mut body) {
            self.stream = None;
            return Err(e);
        }

        Ok(body)
    }

    fn get_tree(&mut self) -> Result<Value, std::io::Error> {
        let body = self.send_message(4, "")?;
        serde_json::from_slice(&body).map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
    }

    fn run_command(&mut self, cmd: &str) -> Result<(), std::io::Error> {
        let _ = self.send_message(0, cmd)?;
        Ok(())
    }
}

fn is_ignored(cls: &str, inst: &str, name: &str) -> bool {
    let lower_cls = cls.to_lowercase();
    let lower_inst = inst.to_lowercase();
    let lower_name = name.to_lowercase();

    for ign in IGNORE_CLASSES {
        if lower_cls.contains(ign) || lower_inst.contains(ign) || lower_name.contains(ign) {
            return true;
        }
    }
    false
}

fn get_icon<'a>(cls: &str, inst: &str, name: &str, icon_map: &HashMap<&str, &'a str>) -> &'a str {
    let lower_cls = cls.to_lowercase();
    let lower_inst = inst.to_lowercase();
    let lower_name = name.to_lowercase();

    for (key, icon) in icon_map {
        if lower_cls.contains(key) || lower_inst.contains(key) || lower_name.contains(key) {
            return icon;
        }
    }
    DEFAULT_ICON
}

fn get_workspace_number(name: &str, re: &Regex) -> String {
    if let Some(caps) = re.captures(name) {
        if let Some(m) = caps.get(1) {
            return m.as_str().to_string();
        }
    }
    name.to_string()
}

fn find_workspaces(node: &Value, out: &mut Vec<Value>) {
    if node.get("type").and_then(|t| t.as_str()) == Some("workspace") {
        if let Some(name) = node.get("name").and_then(|n| n.as_str()) {
            if !name.starts_with("__") {
                out.push(node.clone());
            }
        }
        return;
    }
    if let Some(nodes) = node.get("nodes").and_then(|n| n.as_array()) {
        for n in nodes {
            find_workspaces(n, out);
        }
    }
    if let Some(floating) = node.get("floating_nodes").and_then(|n| n.as_array()) {
        for n in floating {
            find_workspaces(n, out);
        }
    }
}

fn find_leaves(node: &Value, leaves: &mut Vec<Value>) {
    let empty_vec = Vec::new();
    let nodes = node.get("nodes").and_then(|n| n.as_array()).unwrap_or(&empty_vec);
    let floating = node.get("floating_nodes").and_then(|n| n.as_array()).unwrap_or(&empty_vec);

    if nodes.is_empty() && floating.is_empty() {
        if node.get("window").is_some() || node.get("name").is_some() {
            leaves.push(node.clone());
        }
    } else {
        for n in nodes {
            find_leaves(n, leaves);
        }
        for n in floating {
            find_leaves(n, leaves);
        }
    }
}

fn update_workspaces(client: &mut I3Client, icon_map: &HashMap<&str, &str>, re_ws: &Regex) {
    let tree = match client.get_tree() {
        Ok(t) => t,
        Err(_) => return,
    };

    let mut workspaces = Vec::new();
    find_workspaces(&tree, &mut workspaces);

    for ws in workspaces {
        let ws_name = match ws.get("name").and_then(|n| n.as_str()) {
            Some(n) => n,
            None => continue,
        };

        let ws_num = get_workspace_number(ws_name, re_ws);
        let mut leaves = Vec::new();
        find_leaves(&ws, &mut leaves);

        let mut icons: Vec<&str> = Vec::new();
        for w in leaves {
            let name = w.get("name").and_then(|n| n.as_str()).unwrap_or("");
            let (cls, inst) = if let Some(props) = w.get("window_properties") {
                (
                    props.get("class").and_then(|c| c.as_str()).unwrap_or(""),
                    props.get("instance").and_then(|i| i.as_str()).unwrap_or(""),
                )
            } else {
                ("", "")
            };

            if (w.get("window").is_some() || !name.is_empty()) && !is_ignored(cls, inst, name) {
                let icon = get_icon(cls, inst, name, icon_map);
                if !icons.contains(&icon) {
                    icons.push(icon);
                }
            }
        }

        let new_name = if !icons.is_empty() {
            format!("{} {}", ws_num, icons.join(" "))
        } else {
            ws_num
        };

        if ws_name != new_name {
            let cmd = format!("rename workspace \"{}\" to \"{}\"", ws_name, new_name);
            let _ = client.run_command(&cmd);
        }
    }
}

fn main() {
    let sock_path = get_i3_socket_path();
    if sock_path.is_empty() {
        eprintln!("Error: i3 socket path not found. Is i3 running?");
        std::process::exit(1);
    }

    let icon_map = build_icon_map();
    let re_ws = Regex::new(r"^(\d+)").unwrap();

    let client = Arc::new(Mutex::new(I3Client::new(sock_path.clone())));

    // Initial update
    {
        let mut c = client.lock().unwrap();
        update_workspaces(&mut c, &icon_map, &re_ws);
    }

    // Periodic sync thread (every 2 seconds fallback)
    let client_periodic = Arc::clone(&client);
    let re_ws_periodic = re_ws.clone();
    thread::spawn(move || {
        let icon_map_periodic = build_icon_map();
        loop {
            thread::sleep(Duration::from_secs(2));
            if let Ok(mut c) = client_periodic.lock() {
                update_workspaces(&mut c, &icon_map_periodic, &re_ws_periodic);
            }
        }
    });

    // Event listener connection (dedicated UnixStream for subscriptions)
    loop {
        match UnixStream::connect(&sock_path) {
            Ok(mut event_stream) => {
                // Subscribe to window, workspace, mode events
                let payload = r#"["window", "workspace", "mode"]"#;
                let mut sub_msg = Vec::new();
                sub_msg.extend_from_slice(b"i3-ipc");
                sub_msg.extend_from_slice(&(payload.len() as u32).to_ne_bytes());
                sub_msg.extend_from_slice(&2u32.to_ne_bytes());
                sub_msg.extend_from_slice(payload.as_bytes());

                if event_stream.write_all(&sub_msg).is_err() {
                    thread::sleep(Duration::from_secs(1));
                    continue;
                }

                // Read subscribe response
                let mut header = [0u8; 14];
                if event_stream.read_exact(&mut header).is_err() {
                    thread::sleep(Duration::from_secs(1));
                    continue;
                }
                let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
                let mut body = vec![0u8; len];
                let _ = event_stream.read_exact(&mut body);

                // Event loop reading incoming events
                loop {
                    let mut ev_header = [0u8; 14];
                    if event_stream.read_exact(&mut ev_header).is_err() {
                        break;
                    }
                    let ev_len = u32::from_ne_bytes(ev_header[6..10].try_into().unwrap()) as usize;
                    let mut ev_body = vec![0u8; ev_len];
                    if event_stream.read_exact(&mut ev_body).is_err() {
                        break;
                    }

                    // An event occurred! Update workspaces immediately
                    if let Ok(mut c) = client.lock() {
                        update_workspaces(&mut c, &icon_map, &re_ws);
                    }
                }
            }
            Err(_) => {
                thread::sleep(Duration::from_secs(1));
            }
        }
    }
}
