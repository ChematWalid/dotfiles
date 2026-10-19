//! Atomic file writer for Conky desktop output.

use crate::config::output_paths;
use std::fs::{self, OpenOptions};
use std::io::{self, Write};
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

    pub fn write(&mut self, text: &str) -> io::Result<()> {
        let text = text.trim();
        if self.last_written.as_deref() == Some(text) {
            return Ok(());
        }

        if let Some(parent) = self.output.parent() {
            fs::create_dir_all(parent)?;
        }

        let mut file = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&self.temporary)?;
        if let Err(error) = file.write_all(text.as_bytes()) {
            let _ = fs::remove_file(&self.temporary);
            return Err(error);
        }
        drop(file);

        if let Err(error) = fs::rename(&self.temporary, &self.output) {
            let _ = fs::remove_file(&self.temporary);
            return Err(error);
        }
        self.last_written = Some(text.to_owned());
        Ok(())
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
