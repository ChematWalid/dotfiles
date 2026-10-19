//! Atomic file writer for Conky desktop output.

use crate::config::output_paths;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;

pub struct OutputWriter {
    output: PathBuf,
    temporary: PathBuf,
    last_written: Option<String>,
}

impl OutputWriter {
    pub fn new() -> Self {
        let (output, temporary) = output_paths();
        let last_written = fs::read_to_string(&output).ok();
        Self {
            output,
            temporary,
            last_written,
        }
    }

    pub fn write(&mut self, text: &str) {
        let text = text.trim();
        if self.last_written.as_deref() == Some(text) {
            return;
        }

        if let Some(parent) = self.output.parent() {
            if fs::create_dir_all(parent).is_err() {
                return;
            }
        }

        let Ok(mut file) = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&self.temporary)
        else {
            return;
        };
        if file.write_all(text.as_bytes()).is_ok() {
            drop(file);
            if fs::rename(&self.temporary, &self.output).is_ok() {
                self.last_written = Some(text.to_owned());
            } else {
                let _ = fs::remove_file(&self.temporary);
            }
        } else {
            let _ = fs::remove_file(&self.temporary);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_atomic_write() {
        let (output, _) = output_paths();
        let mut writer = OutputWriter::new();
        writer.write("Test Track");
        let read = fs::read_to_string(output).unwrap();
        assert_eq!(read, "Test Track");
        // Clean up
        writer.write("");
    }
}
