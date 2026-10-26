//! i3 IPC protocol connection and command communication.

use std::env;
use std::io::{self, Read, Write};
use std::os::unix::net::UnixStream;
use std::process::Command;

use serde::Deserialize;

use crate::tree::I3Node;

/// Locates the active i3/sway IPC socket path.
pub fn get_i3_socket_path() -> io::Result<String> {
    for variable in ["I3SOCK", "SWAYSOCK"] {
        if let Ok(sock) = env::var(variable) {
            if !sock.is_empty() && UnixStream::connect(&sock).is_ok() {
                return Ok(sock);
            }
        }
    }

    if let Ok(out) = Command::new("i3").arg("--get-socketpath").output() {
        let path = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !path.is_empty() && UnixStream::connect(&path).is_ok() {
            return Ok(path);
        }
    }

    Err(io::Error::new(
        io::ErrorKind::NotFound,
        "could not find valid i3 IPC socket (checked I3SOCK, SWAYSOCK, and `i3 --get-socketpath`)",
    ))
}

pub struct I3Connection {
    stream: UnixStream,
    read_buf: Vec<u8>,
    send_buf: Vec<u8>,
}

#[derive(Deserialize)]
struct CommandReply {
    success: Option<bool>,
    error: Option<String>,
}

impl I3Connection {
    pub fn connect() -> io::Result<Self> {
        let path = get_i3_socket_path()?;
        let stream = UnixStream::connect(path)?;
        stream.set_read_timeout(Some(std::time::Duration::from_secs(3)))?;
        stream.set_write_timeout(Some(std::time::Duration::from_secs(3)))?;
        Ok(Self {
            stream,
            read_buf: Vec::with_capacity(16384),
            send_buf: Vec::with_capacity(256),
        })
    }

    pub fn send_message(&mut self, msg_type: u32, payload: &str) -> io::Result<&[u8]> {
        self.send_buf.clear();
        self.send_buf.reserve(14 + payload.len());
        self.send_buf.extend_from_slice(b"i3-ipc");
        self.send_buf
            .extend_from_slice(&(payload.len() as u32).to_ne_bytes());
        self.send_buf.extend_from_slice(&msg_type.to_ne_bytes());
        self.send_buf.extend_from_slice(payload.as_bytes());

        self.stream.write_all(&self.send_buf)?;

        let mut header = [0u8; 14];
        self.stream.read_exact(&mut header)?;

        if &header[..6] != b"i3-ipc" {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid i3 IPC magic header",
            ));
        }

        let reply_type = u32::from_ne_bytes(header[10..14].try_into().unwrap());
        if reply_type != msg_type {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unexpected i3 IPC reply type {reply_type} for message {msg_type}"),
            ));
        }

        let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
        if len > 32 * 1024 * 1024 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("oversized i3 IPC payload length: {len}"),
            ));
        }

        self.read_buf.resize(len, 0);
        self.stream.read_exact(&mut self.read_buf)?;

        Ok(&self.read_buf)
    }

    pub fn get_tree(&mut self) -> io::Result<I3Node> {
        let body = self.send_message(4, "")?;
        serde_json::from_slice(body).map_err(|e| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("failed to parse i3 tree JSON: {e}"),
            )
        })
    }

    pub fn run_command(&mut self, cmd: &str) -> io::Result<()> {
        let body = self.send_message(0, cmd)?;
        let replies: Vec<CommandReply> = serde_json::from_slice(body).map_err(|e| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("failed to parse i3 command response: {e}"),
            )
        })?;

        for reply in replies {
            if reply.success != Some(true) {
                let err_msg = reply.error.unwrap_or_else(|| "unknown error".into());
                return Err(io::Error::other(format!("i3 rejected command: {err_msg}")));
            }
        }

        Ok(())
    }
}
