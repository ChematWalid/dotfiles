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
    event_changes_workspace_icons, get_i3_socket_path, is_stream_disconnect,
    is_transient_ipc_error, subscribe_events, wait_for_i3_socket_after_failure, I3Client,
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
    if let Err(error) = update_workspaces(&mut client) {
        if !is_transient_ipc_error(&error) {
            eprintln!("autoname-workspaces: initial workspace update failed: {error}");
        }
    }

    // Event listener subscription loop
    let mut retry_delay = Duration::from_millis(50);
    loop {
        let mut event_stream = match subscribe_events(&sock_path) {
            Ok(stream) => stream,
            Err(error) => {
                if !is_transient_ipc_error(&error) {
                    eprintln!("autoname-workspaces: i3 event subscription failed: {error}");
                }
                sock_path = wait_for_i3_socket_after_failure(&sock_path, &mut retry_delay);
                client = I3Client::new(sock_path.clone());
                if let Err(error) = update_workspaces(&mut client) {
                    if !is_transient_ipc_error(&error) {
                        eprintln!("autoname-workspaces: workspace update failed: {error}");
                    }
                }
                continue;
            }
        };

        let mut ev_body = Vec::new();
        loop {
            let mut ev_header = [0u8; 14];
            if let Err(error) = event_stream.read_exact(&mut ev_header) {
                if !is_stream_disconnect(&error) {
                    eprintln!("autoname-workspaces: could not read i3 event header: {error}");
                }
                break;
            }
            let ev_len = u32::from_ne_bytes(ev_header[6..10].try_into().unwrap()) as usize;
            let ev_type = u32::from_ne_bytes(ev_header[10..14].try_into().unwrap());
            ev_body.resize(ev_len, 0);
            if let Err(error) = event_stream.read_exact(&mut ev_body) {
                if !is_stream_disconnect(&error) {
                    eprintln!("autoname-workspaces: could not read i3 event: {error}");
                }
                break;
            }

            retry_delay = Duration::from_millis(50);
            if event_changes_workspace_icons(ev_type, &ev_body) {
                if let Err(error) = update_workspaces(&mut client) {
                    if !is_transient_ipc_error(&error) {
                        eprintln!("autoname-workspaces: workspace update failed: {error}");
                    }
                }
            }
        }

        sock_path = wait_for_i3_socket_after_failure(&sock_path, &mut retry_delay);
        client = I3Client::new(sock_path.clone());
        if let Err(error) = update_workspaces(&mut client) {
            if !is_transient_ipc_error(&error) {
                eprintln!("autoname-workspaces: workspace update failed: {error}");
            }
        }
    }
}
