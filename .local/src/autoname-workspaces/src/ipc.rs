//! i3 IPC protocol connection and message serialization.

use serde_json::Value;
use std::env;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::process::Command;

pub fn get_i3_socket_path() -> String {
    if let Ok(sock) = env::var("I3SOCK") {
        if !sock.is_empty() {
            return sock;
        }
    }
    if let Ok(sock) = env::var("SWAYSOCK") {
        if !sock.is_empty() {
            return sock;
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

        let mut msg = Vec::new();
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

    pub fn get_tree(&mut self) -> Result<Value, std::io::Error> {
        let body = self.send_message(4, "")?;
        serde_json::from_slice(&body)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
    }

    pub fn run_command(&mut self, cmd: &str) -> Result<(), std::io::Error> {
        let _ = self.send_message(0, cmd)?;
        Ok(())
    }
}

pub fn subscribe_events(sock_path: &str) -> Result<UnixStream, std::io::Error> {
    let mut stream = UnixStream::connect(sock_path)?;
    let payload = r#"["window", "workspace", "mode"]"#;
    let mut sub_msg = Vec::new();
    sub_msg.extend_from_slice(b"i3-ipc");
    sub_msg.extend_from_slice(&(payload.len() as u32).to_ne_bytes());
    sub_msg.extend_from_slice(&2u32.to_ne_bytes());
    sub_msg.extend_from_slice(payload.as_bytes());

    stream.write_all(&sub_msg)?;

    let mut header = [0u8; 14];
    stream.read_exact(&mut header)?;
    let len = u32::from_ne_bytes(header[6..10].try_into().unwrap()) as usize;
    let mut body = vec![0u8; len];
    stream.read_exact(&mut body)?;

    Ok(stream)
}
