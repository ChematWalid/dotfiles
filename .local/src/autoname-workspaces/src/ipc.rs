//! i3 IPC protocol connection and message serialization.

use serde::Deserialize;
use serde_json::Value;
use std::env;
use std::ffi::CString;
use std::fs::File;
use std::io::{self, Read, Write};
use std::os::fd::{AsRawFd, FromRawFd};
use std::os::raw::{c_char, c_int};
use std::os::unix::ffi::OsStrExt;
use std::os::unix::net::UnixStream;
use std::path::Path;
use std::process::Command;
use std::thread;
use std::time::Duration;

const IN_CLOEXEC: c_int = 0o2000000;
const IN_CREATE: u32 = 0x0000_0100;
const IN_DELETE: u32 = 0x0000_0200;
const IN_MOVED_FROM: u32 = 0x0000_0040;
const IN_MOVED_TO: u32 = 0x0000_0080;
const IN_DELETE_SELF: u32 = 0x0000_0400;
const IN_MOVE_SELF: u32 = 0x0000_0800;
const IN_Q_OVERFLOW: u32 = 0x0000_4000;

#[derive(Deserialize)]
struct EventChange<'a> {
    #[serde(borrow)]
    change: Option<&'a str>,
}

pub fn event_change(body: &[u8]) -> Option<&str> {
    serde_json::from_slice::<EventChange<'_>>(body)
        .ok()
        .and_then(|event| event.change)
}

/// i3 closes subscribed event sockets while restarting or reloading. Treat
/// those normal stream shutdowns as reconnect signals instead of user-facing
/// errors; other I/O failures remain reportable.
pub fn is_stream_disconnect(error: &io::Error) -> bool {
    matches!(
        error.kind(),
        io::ErrorKind::UnexpectedEof
            | io::ErrorKind::ConnectionReset
            | io::ErrorKind::ConnectionAborted
            | io::ErrorKind::BrokenPipe
            | io::ErrorKind::NotConnected
    )
}

#[repr(C)]
struct InotifyEvent {
    wd: i32,
    mask: u32,
    cookie: u32,
    len: u32,
}

unsafe extern "C" {
    fn inotify_init1(flags: c_int) -> c_int;
    fn inotify_add_watch(fd: c_int, pathname: *const c_char, mask: u32) -> c_int;
}

pub fn get_i3_socket_path() -> String {
    for variable in ["I3SOCK", "SWAYSOCK"] {
        if let Ok(sock) = env::var(variable) {
            if !sock.is_empty() && UnixStream::connect(&sock).is_ok() {
                return sock;
            }
        }
    }
    if let Ok(out) = Command::new("i3").arg("--get-socketpath").output() {
        let path = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !path.is_empty() {
            return path;
        }
    }
    String::new()
}

/// Block on an inotify event while i3 replaces its IPC socket, then return the
/// currently connectable socket path. The one-second sleep is only a fallback
/// for missing or unavailable inotify support.
pub fn wait_for_i3_socket(sock_path: &str) -> String {
    let parent = Path::new(sock_path)
        .parent()
        .unwrap_or_else(|| Path::new("/"));
    let Ok(mut watcher) = watch_directory(parent) else {
        thread::sleep(Duration::from_secs(1));
        return get_i3_socket_path();
    };

    loop {
        let current_path = get_i3_socket_path();
        if !current_path.is_empty() && UnixStream::connect(&current_path).is_ok() {
            return current_path;
        }

        if wait_for_directory_entry(&mut watcher).is_err() {
            thread::sleep(Duration::from_secs(1));
            return get_i3_socket_path();
        }
    }
}

/// Back off only when the socket is still accepting connections but a watcher
/// could not subscribe or its event stream ended. If i3 is restarting, wait on
/// the socket directory events instead of delaying reconnection.
pub fn wait_for_i3_socket_after_failure(sock_path: &str, retry_delay: &mut Duration) -> String {
    let current_path = get_i3_socket_path();
    if !current_path.is_empty() && UnixStream::connect(&current_path).is_ok() {
        thread::sleep(*retry_delay);
        *retry_delay = (*retry_delay * 2).min(Duration::from_secs(2));
        current_path
    } else {
        *retry_delay = Duration::from_millis(50);
        wait_for_i3_socket(sock_path)
    }
}

fn watch_directory(path: &Path) -> io::Result<File> {
    let path = CString::new(path.as_os_str().as_bytes())
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "invalid socket directory"))?;
    let fd = unsafe { inotify_init1(IN_CLOEXEC) };
    if fd < 0 {
        return Err(io::Error::last_os_error());
    }

    let file = unsafe { File::from_raw_fd(fd) };
    let mask = IN_CREATE | IN_DELETE | IN_MOVED_FROM | IN_MOVED_TO | IN_DELETE_SELF | IN_MOVE_SELF;
    if unsafe { inotify_add_watch(file.as_raw_fd(), path.as_ptr(), mask) } < 0 {
        return Err(io::Error::last_os_error());
    }
    Ok(file)
}

fn wait_for_directory_entry(watcher: &mut File) -> io::Result<()> {
    let mut buffer = [0u64; 512];
    loop {
        let bytes = match watcher.read(unsafe {
            std::slice::from_raw_parts_mut(
                buffer.as_mut_ptr().cast::<u8>(),
                std::mem::size_of_val(&buffer),
            )
        }) {
            Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
            result => result?,
        };
        if bytes == 0 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "inotify watcher closed",
            ));
        }

        let mut offset = 0;
        while offset + std::mem::size_of::<InotifyEvent>() <= bytes {
            let event = unsafe {
                &*buffer
                    .as_ptr()
                    .cast::<u8>()
                    .add(offset)
                    .cast::<InotifyEvent>()
            };
            let event_size = std::mem::size_of::<InotifyEvent>() + event.len as usize;
            if event_size > bytes - offset {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    "truncated inotify event",
                ));
            }
            if event.mask & (IN_DELETE_SELF | IN_MOVE_SELF | IN_Q_OVERFLOW) != 0 {
                return Ok(());
            }
            if event.len > 0 {
                let name_start = offset + std::mem::size_of::<InotifyEvent>();
                let name = unsafe {
                    std::slice::from_raw_parts(
                        buffer.as_ptr().cast::<u8>().add(name_start),
                        event.len as usize,
                    )
                };
                let name_len = name
                    .iter()
                    .position(|byte| *byte == 0)
                    .unwrap_or(name.len());
                let name = &name[..name_len];
                if name.starts_with(b"ipc-socket.") || name.starts_with(b"sway-ipc.") {
                    return Ok(());
                }
            }
            offset += event_size;
        }
    }
}

pub struct I3Client {
    sock_path: String,
    stream: Option<UnixStream>,
}

impl I3Client {
    pub fn new(sock_path: String) -> Self {
        Self {
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

    pub fn send_message(
        &mut self,
        msg_type: u32,
        payload: &str,
    ) -> Result<Vec<u8>, std::io::Error> {
        let stream = self.ensure_connected()?;

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

        if &header[..6] != b"i3-ipc" {
            self.stream = None;
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid i3 IPC response magic",
            ));
        }
        let reply_type = u32::from_ne_bytes(header[10..14].try_into().unwrap());
        if reply_type != msg_type {
            self.stream = None;
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unexpected i3 IPC reply type {reply_type} for request {msg_type}"),
            ));
        }

        let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
        let mut body = vec![0u8; len];
        if let Err(e) = stream.read_exact(&mut body) {
            self.stream = None;
            return Err(e);
        }

        Ok(body)
    }

    pub fn get_tree(&mut self) -> Result<Value, std::io::Error> {
        let body = self.send_message(4, "")?;
        serde_json::from_slice(&body)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
    }

    pub fn run_command(&mut self, cmd: &str) -> Result<(), std::io::Error> {
        let body = self.send_message(0, cmd)?;
        let replies: Vec<Value> = serde_json::from_slice(&body)
            .map_err(|error| std::io::Error::new(std::io::ErrorKind::InvalidData, error))?;
        for reply in replies {
            if reply.get("success").and_then(Value::as_bool) != Some(true) {
                let detail = reply
                    .get("error")
                    .or_else(|| reply.get("parse_error"))
                    .unwrap_or(&reply);
                return Err(std::io::Error::new(
                    std::io::ErrorKind::InvalidInput,
                    format!("i3 rejected command: {detail}"),
                ));
            }
        }
        Ok(())
    }
}

pub fn subscribe_events(sock_path: &str) -> Result<UnixStream, std::io::Error> {
    subscribe_events_with_payload(sock_path, r#"["window", "workspace"]"#)
}

pub fn subscribe_events_with_payload(
    sock_path: &str,
    payload: &str,
) -> Result<UnixStream, std::io::Error> {
    let mut stream = UnixStream::connect(sock_path)?;
    let mut sub_msg = Vec::with_capacity(14 + payload.len());
    sub_msg.extend_from_slice(b"i3-ipc");
    sub_msg.extend_from_slice(&(payload.len() as u32).to_ne_bytes());
    sub_msg.extend_from_slice(&2u32.to_ne_bytes());
    sub_msg.extend_from_slice(payload.as_bytes());

    stream.write_all(&sub_msg)?;

    let mut header = [0u8; 14];
    stream.read_exact(&mut header)?;
    if &header[..6] != b"i3-ipc" {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "invalid i3 IPC response magic",
        ));
    }
    let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
    let reply_type = u32::from_ne_bytes(header[10..14].try_into().unwrap());
    if reply_type != 2 {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!("unexpected i3 IPC subscription reply type {reply_type}"),
        ));
    }
    let mut body = vec![0u8; len];
    stream.read_exact(&mut body)?;
    let reply: Value = serde_json::from_slice(&body)
        .map_err(|error| io::Error::new(io::ErrorKind::InvalidData, error))?;
    if reply.get("success").and_then(Value::as_bool) != Some(true) {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!("i3 rejected event subscription: {reply}"),
        ));
    }

    Ok(stream)
}

/// i3 event IDs have the high bit set; the low 31 bits identify the event.
/// Workspace focus and window focus do not change the set of icons on any
/// workspace, so skip those events instead of fetching and parsing the tree.
pub fn event_changes_workspace_icons(event_type: u32, body: &[u8]) -> bool {
    const WORKSPACE_EVENT: u32 = 0x8000_0000;
    const WINDOW_EVENT: u32 = 0x8000_0003;

    let Some(change) = event_change(body) else {
        // Unknown payloads should trigger a refresh to preserve correctness.
        return true;
    };

    match event_type {
        WORKSPACE_EVENT => matches!(change, "init" | "empty" | "move" | "rename" | "restored"),
        WINDOW_EVENT => matches!(change, "new" | "close" | "title" | "move"),
        _ => true,
    }
}

#[cfg(test)]
mod tests {
    use super::event_changes_workspace_icons;

    #[test]
    fn skips_focus_events_and_handles_icon_changes() {
        const WORKSPACE: u32 = 0x8000_0000;
        const WINDOW: u32 = 0x8000_0003;

        assert!(!event_changes_workspace_icons(
            WORKSPACE,
            br#"{"change":"focus"}"#
        ));
        assert!(!event_changes_workspace_icons(
            WINDOW,
            br#"{"change":"focus"}"#
        ));
        assert!(event_changes_workspace_icons(
            WORKSPACE,
            br#"{"change":"empty"}"#
        ));
        assert!(event_changes_workspace_icons(
            WINDOW,
            br#"{"change":"title"}"#
        ));
        assert!(event_changes_workspace_icons(
            WORKSPACE,
            br#"{"change":"restored"}"#
        ));
    }

    #[test]
    fn refreshes_on_unknown_or_invalid_events() {
        assert!(event_changes_workspace_icons(99, br#"{"change":"focus"}"#));
        assert!(event_changes_workspace_icons(99, b"not json"));
    }
}
