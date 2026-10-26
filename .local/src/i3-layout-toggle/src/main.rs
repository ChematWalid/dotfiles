//! i3-layout-toggle — Robust and reliable layout switcher for i3 window manager.
//! High-performance native Rust implementation.

mod ipc;
mod layout;
mod tree;

use std::env;
use std::fs::File;
use std::path::Path;

use ipc::I3Connection;
use layout::{plan_layout, Action, LayoutPlan};
use tree::{build_container_path, get_active_leaf, get_eligible_grouping_containers};

fn acquire_lock() -> Option<File> {
    let runtime_dir = env::var("XDG_RUNTIME_DIR").unwrap_or_else(|_| {
        let uid = unsafe { libc_getuid() };
        format!("/run/user/{uid}")
    });
    let lock_path = Path::new(&runtime_dir).join("i3-layout-toggle.lock");
    let file = std::fs::OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(false)
        .open(lock_path)
        .ok()?;

    use std::os::fd::AsRawFd;
    let fd = file.as_raw_fd();
    unsafe {
        extern "C" {
            fn flock(
                fd: std::os::raw::c_int,
                operation: std::os::raw::c_int,
            ) -> std::os::raw::c_int;
        }
        const LOCK_EX: std::os::raw::c_int = 2;
        flock(fd, LOCK_EX);
    }
    Some(file)
}

unsafe fn libc_getuid() -> u32 {
    extern "C" {
        fn getuid() -> u32;
    }
    getuid()
}

fn parse_action() -> Action {
    let first = env::args().nth(1);
    match first.as_deref() {
        Some("-h" | "--help") => {
            println!("Usage: i3-layout-toggle [tab|toggle|untab|split]");
            std::process::exit(0);
        }
        Some("-v" | "--version") => {
            println!("i3-layout-toggle {}", env!("CARGO_PKG_VERSION"));
            std::process::exit(0);
        }
        Some(s) if s.eq_ignore_ascii_case("tab") => Action::Tab,
        _ => Action::Toggle,
    }
}

fn main() {
    let action = parse_action();
    let _lock = acquire_lock();

    let mut i3 = match I3Connection::connect() {
        Ok(conn) => conn,
        Err(e) => {
            eprintln!("i3-layout-toggle: failed to connect to i3 IPC: {e}");
            std::process::exit(1);
        }
    };

    let tree = match i3.get_tree() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("i3-layout-toggle: failed to get i3 tree: {e}");
            std::process::exit(1);
        }
    };

    let focused = tree.find_focused();
    let was_container_focused = focused.is_some_and(|f| {
        !f.nodes.is_empty()
            && f.node_type != "root"
            && f.node_type != "output"
            && f.node_type != "dockarea"
            && f.name.as_deref() != Some("content")
    });

    let leaf = match get_active_leaf(&tree, focused) {
        Some(l) => l,
        None => {
            let cmd = match action {
                Action::Tab => "layout tabbed",
                Action::Toggle => "layout toggle split",
            };
            let _ = i3.run_command(cmd);
            std::process::exit(0);
        }
    };

    let path = build_container_path(&tree, leaf.id);
    let eligible = get_eligible_grouping_containers(&path);
    let focused_ref = focused.unwrap_or(leaf);
    let plan = plan_layout(
        action,
        focused_ref,
        leaf,
        &path,
        &eligible,
        was_container_focused,
    );

    match plan {
        LayoutPlan::ExecuteCommand(cmd) => {
            if let Err(e) = i3.run_command(&cmd) {
                eprintln!("i3-layout-toggle: command failed: {e}");
                std::process::exit(1);
            }
        }
        LayoutPlan::FocusLeaf(leaf_id) => {
            let cmd = format!("[con_id={leaf_id}] focus");
            let _ = i3.run_command(&cmd);
        }
        LayoutPlan::DirectLayout(cmd) => {
            let _ = i3.run_command(cmd);
        }
        LayoutPlan::NoOp => {}
    }
}
