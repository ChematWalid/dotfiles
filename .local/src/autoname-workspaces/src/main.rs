//! autoname-workspaces — Dynamically updates i3 workspace names with Nerd Font application icons.
//! High-performance native Rust using raw i3 IPC event subscriptions.

mod autotiling;
mod config;
mod icons;
mod ipc;
mod workspace;

use std::io::Read;
use std::time::Duration;

use ipc::{
    event_changes_workspace_icons, get_i3_socket_path, subscribe_events,
    wait_for_i3_socket_after_failure, I3Client,
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
    let mut retry_delay = Duration::from_millis(50);
    loop {
        let mut event_stream = match subscribe_events(&sock_path) {
            Ok(stream) => stream,
            Err(error) => {
                eprintln!("autoname-workspaces: i3 event subscription failed: {error}");
                sock_path = wait_for_i3_socket_after_failure(&sock_path, &mut retry_delay);
                client = I3Client::new(sock_path.clone());
                update_workspaces(&mut client);
                continue;
            }
        };

        let mut ev_body = Vec::new();
        loop {
            let mut ev_header = [0u8; 14];
            if let Err(error) = event_stream.read_exact(&mut ev_header) {
                eprintln!("autoname-workspaces: i3 event stream ended: {error}");
                break;
            }
            let ev_len = u32::from_ne_bytes(ev_header[6..10].try_into().unwrap()) as usize;
            let ev_type = u32::from_ne_bytes(ev_header[10..14].try_into().unwrap());
            ev_body.resize(ev_len, 0);
            if let Err(error) = event_stream.read_exact(&mut ev_body) {
                eprintln!("autoname-workspaces: could not read i3 event: {error}");
                break;
            }

            retry_delay = Duration::from_millis(50);
            if event_changes_workspace_icons(ev_type, &ev_body) {
                update_workspaces(&mut client);
            }
        }

        sock_path = wait_for_i3_socket_after_failure(&sock_path, &mut retry_delay);
        client = I3Client::new(sock_path.clone());
        update_workspaces(&mut client);
    }
}
