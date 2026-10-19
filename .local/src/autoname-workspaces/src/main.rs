//! autoname-workspaces — Dynamically updates i3 workspace names with Nerd Font application icons.
//! High-performance native Rust using raw i3 IPC event subscriptions.

mod autotiling;
mod config;
mod icons;
mod ipc;
mod workspace;

use std::io::Read;

use ipc::{
    event_changes_workspace_icons, get_i3_socket_path, subscribe_events, wait_for_i3_socket,
    I3Client,
};
use workspace::update_workspaces;

fn main() {
    if std::env::args().any(|arg| arg == "--autotiling") {
        autotiling::run();
        return;
    }

    let mut sock_path = get_i3_socket_path();
    if sock_path.is_empty() {
        eprintln!("Error: i3 socket path not found. Is i3 running?");
        std::process::exit(1);
    }

    let mut client = I3Client::new(sock_path.clone());

    // Initial update
    update_workspaces(&mut client);

    // Event listener subscription loop
    loop {
        if let Ok(mut event_stream) = subscribe_events(&sock_path) {
            let mut ev_body = Vec::new();
            loop {
                let mut ev_header = [0u8; 14];
                if event_stream.read_exact(&mut ev_header).is_err() {
                    break;
                }
                let ev_len = u32::from_ne_bytes(ev_header[6..10].try_into().unwrap()) as usize;
                let ev_type = u32::from_ne_bytes(ev_header[10..14].try_into().unwrap());
                ev_body.resize(ev_len, 0);
                if event_stream.read_exact(&mut ev_body).is_err() {
                    break;
                }

                if event_changes_workspace_icons(ev_type, &ev_body) {
                    update_workspaces(&mut client);
                }
            }
        }

        sock_path = wait_for_i3_socket(&sock_path);
        client = I3Client::new(sock_path.clone());
        update_workspaces(&mut client);
    }
}
