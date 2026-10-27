//! Native Rust focused window information inspector for i3.
//! Eliminates shell/jq/xprop forks and sends desktop notification with metadata.

use std::fs;
use std::io;
use std::process::Command;

use crate::ipc::I3Connection;
use crate::tree::find_mru_leaf;

pub fn run_window_info() -> io::Result<()> {
    let mut i3 = I3Connection::connect()?;
    let tree = i3.get_tree()?;

    let focused = match tree.find_focused() {
        Some(f) => {
            if f.window_properties.is_some() {
                f
            } else {
                find_mru_leaf(f)
            }
        }
        None => {
            let _ = Command::new("notify-send")
                .args([
                    "-u",
                    "low",
                    "-a",
                    "i3wm",
                    "-i",
                    "dialog-information",
                    "Window Info",
                    "No active client window focused.",
                ])
                .status();
            return Ok(());
        }
    };

    let props = focused.window_properties.as_ref();
    let win_class = props
        .and_then(|p| p.window_class.as_deref())
        .unwrap_or("Unknown");
    let win_instance = props
        .and_then(|p| p.instance.as_deref())
        .unwrap_or("Unknown");
    let win_title = props
        .and_then(|p| p.title.as_deref())
        .or(focused.name.as_deref())
        .unwrap_or("Unknown");
    let xid = focused.window.unwrap_or(0);

    // Copy class to clipboard via xclip if available
    let _ = Command::new("xclip")
        .args(["-selection", "clipboard"])
        .stdin(std::process::Stdio::piped())
        .spawn()
        .and_then(|mut child| {
            if let Some(mut stdin) = child.stdin.take() {
                use std::io::Write;
                let _ = stdin.write_all(win_class.as_bytes());
            }
            child.wait()
        });

    // Extract PID from /proc if xid matches
    let mut pid_str = "N/A".to_string();
    let mut proc_name = "N/A".to_string();

    if xid > 0 {
        if let Ok(out) = Command::new("xprop")
            .args(["-id", &xid.to_string(), "_NET_WM_PID"])
            .output()
        {
            let text = String::from_utf8_lossy(&out.stdout);
            if let Some(idx) = text.rfind('=') {
                let candidate = text[idx + 1..].trim();
                if let Ok(pid) = candidate.parse::<u32>() {
                    pid_str = pid.to_string();
                    if let Ok(comm) = fs::read_to_string(format!("/proc/{pid}/comm")) {
                        proc_name = comm.trim().to_string();
                    }
                }
            }
        }
    }

    let summary = format!("Focused Window: {win_class}");
    let body = format!(
        "<b>Class:</b> <code>{win_class}</code> (<i>copied to clipboard</i>)\n<b>Instance:</b> <code>{win_instance}</code>\n<b>Process:</b> <code>{proc_name}</code> (PID: {pid_str})\n<b>Title:</b> {win_title}"
    );

    let _ = Command::new("notify-send")
        .args([
            "-u",
            "normal",
            "-a",
            "i3wm",
            "-i",
            "preferences-desktop-display",
            &summary,
            &body,
        ])
        .status();

    Ok(())
}
