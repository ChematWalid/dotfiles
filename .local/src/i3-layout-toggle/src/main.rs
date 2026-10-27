//! i3-layout-toggle — Robust and reliable layout switcher and window manager helper for i3.
//! High-performance native Rust implementation.

mod autotiling_toggle;
mod ipc;
mod layout;
mod scratchpad;
mod status;
mod tree;
mod window_info;

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

#[derive(Debug, PartialEq, Eq)]
enum AppCommand {
    Layout(Action),
    Scratchpad,
    WindowInfo,
    AutotilingToggle,
    Status { json: bool },
    Help,
    Version,
}

fn parse_command_args(first: Option<&str>, second: Option<&str>) -> Result<AppCommand, String> {
    match first {
        Some("-h" | "--help") => Ok(AppCommand::Help),
        Some("-v" | "--version") => Ok(AppCommand::Version),
        Some(s) if s.eq_ignore_ascii_case("scratchpad") => Ok(AppCommand::Scratchpad),
        Some(s) if s.eq_ignore_ascii_case("window-info") || s.eq_ignore_ascii_case("info") => {
            Ok(AppCommand::WindowInfo)
        }
        Some(s)
            if s.eq_ignore_ascii_case("autotiling-toggle")
                || s.eq_ignore_ascii_case("autotiling") =>
        {
            Ok(AppCommand::AutotilingToggle)
        }
        Some(s) if s.eq_ignore_ascii_case("status") => {
            let json = match second {
                Some("--json" | "-j") => true,
                Some(other) => return Err(format!("unknown option '{other}' for status")),
                None => false,
            };
            Ok(AppCommand::Status { json })
        }
        Some(s) if s.eq_ignore_ascii_case("tab") => Ok(AppCommand::Layout(Action::Tab)),
        Some(s)
            if s.eq_ignore_ascii_case("toggle")
                || s.eq_ignore_ascii_case("untab")
                || s.eq_ignore_ascii_case("split") =>
        {
            Ok(AppCommand::Layout(Action::Toggle))
        }
        None => Ok(AppCommand::Layout(Action::Toggle)),
        Some(other) => Err(format!("unknown subcommand '{other}'")),
    }
}

fn parse_command() -> AppCommand {
    let first = env::args().nth(1);
    let second = env::args().nth(2);
    match parse_command_args(first.as_deref(), second.as_deref()) {
        Ok(AppCommand::Help) => {
            use std::io::Write;
            let stdout = std::io::stdout();
            let mut handle = stdout.lock();
            let _ = writeln!(
                handle,
                "Usage: i3-layout-toggle [tab|toggle|untab|split|scratchpad|window-info|autotiling-toggle|status [--json]]"
            );
            std::process::exit(0);
        }
        Ok(AppCommand::Version) => {
            use std::io::Write;
            let stdout = std::io::stdout();
            let mut handle = stdout.lock();
            let _ = writeln!(handle, "i3-layout-toggle {}", env!("CARGO_PKG_VERSION"));
            std::process::exit(0);
        }
        Ok(cmd) => cmd,
        Err(e) => {
            eprintln!("i3-layout-toggle: {e}");
            eprintln!("Usage: i3-layout-toggle [tab|toggle|untab|split|scratchpad|window-info|autotiling-toggle|status [--json]]");
            std::process::exit(1);
        }
    }
}

fn run_layout_action(action: Action) {
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
            return;
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
                eprintln!("i3-layout-toggle: command failed ({cmd}): {e}");
            }
        }
        LayoutPlan::FocusLeaf(id) => {
            let cmd = format!("[con_id={id}] focus");
            let _ = i3.run_command(&cmd);
        }
        LayoutPlan::DirectLayout(cmd) => {
            let _ = i3.run_command(cmd);
        }
        LayoutPlan::NoOp => {}
    }
}

fn main() {
    match parse_command() {
        AppCommand::Scratchpad => {
            if let Err(e) = scratchpad::run_scratchpad_toggle() {
                eprintln!("i3-layout-toggle scratchpad error: {e}");
                std::process::exit(1);
            }
        }
        AppCommand::WindowInfo => {
            if let Err(e) = window_info::run_window_info() {
                eprintln!("i3-layout-toggle window-info error: {e}");
                std::process::exit(1);
            }
        }
        AppCommand::AutotilingToggle => {
            if let Err(e) = autotiling_toggle::run_autotiling_toggle() {
                eprintln!("i3-layout-toggle autotiling error: {e}");
                std::process::exit(1);
            }
        }
        AppCommand::Status { json } => {
            if let Err(e) = status::run_status(json) {
                eprintln!("i3-layout-toggle status error: {e}");
                std::process::exit(1);
            }
        }
        AppCommand::Layout(action) => {
            run_layout_action(action);
        }
        AppCommand::Help | AppCommand::Version => unreachable!(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_command_args() {
        assert_eq!(parse_command_args(Some("tab"), None), Ok(AppCommand::Layout(Action::Tab)));
        assert_eq!(parse_command_args(Some("toggle"), None), Ok(AppCommand::Layout(Action::Toggle)));
        assert_eq!(parse_command_args(Some("untab"), None), Ok(AppCommand::Layout(Action::Toggle)));
        assert_eq!(parse_command_args(Some("split"), None), Ok(AppCommand::Layout(Action::Toggle)));
        assert_eq!(parse_command_args(Some("scratchpad"), None), Ok(AppCommand::Scratchpad));
        assert_eq!(parse_command_args(Some("window-info"), None), Ok(AppCommand::WindowInfo));
        assert_eq!(parse_command_args(Some("info"), None), Ok(AppCommand::WindowInfo));
        assert_eq!(parse_command_args(Some("autotiling-toggle"), None), Ok(AppCommand::AutotilingToggle));
        assert_eq!(parse_command_args(Some("autotiling"), None), Ok(AppCommand::AutotilingToggle));
        assert_eq!(parse_command_args(Some("status"), None), Ok(AppCommand::Status { json: false }));
        assert_eq!(parse_command_args(Some("status"), Some("--json")), Ok(AppCommand::Status { json: true }));
        assert_eq!(parse_command_args(Some("status"), Some("-j")), Ok(AppCommand::Status { json: true }));
        assert!(parse_command_args(Some("status"), Some("--invalid")).is_err());
        assert_eq!(parse_command_args(None, None), Ok(AppCommand::Layout(Action::Toggle)));
        assert_eq!(parse_command_args(Some("-h"), None), Ok(AppCommand::Help));
        assert_eq!(parse_command_args(Some("--version"), None), Ok(AppCommand::Version));
        assert!(parse_command_args(Some("unknown-cmd"), None).is_err());
    }
}

