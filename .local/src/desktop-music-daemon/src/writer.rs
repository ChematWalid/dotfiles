//! Atomic file writer for Conky desktop output.

use crate::config::output_paths;
use anyhow::{Context, Result};
use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::PathBuf;

pub struct OutputWriter {
    output: PathBuf,
    temporary: PathBuf,
    last_written: Option<String>,
}

impl OutputWriter {
    pub fn new() -> Result<Self> {
        let (output, temporary) = output_paths()?;
        Self::with_paths(output, temporary)
    }

    pub fn with_paths(output: PathBuf, temporary: PathBuf) -> Result<Self> {
        let last_written = match fs::read_to_string(&output) {
            Ok(text) => Some(text),
            Err(error) if error.kind() == io::ErrorKind::NotFound => None,
            Err(error) => {
                return Err(error).with_context(|| {
                    format!("could not read existing Conky output {}", output.display())
                });
            }
        };
        Ok(Self {
            output,
            temporary,
            last_written,
        })
    }

    pub fn write(&mut self, text: &str) -> Result<()> {
        let text = text.trim();
        if self.last_written.as_deref() == Some(text) {
            return Ok(());
        }

        if let Some(parent) = self.output.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("could not create {}", parent.display()))?;
        }

        let mut file = OpenOptions::new()
            .write(true)
            .create(true)
            .truncate(true)
            .open(&self.temporary)
            .with_context(|| format!("could not open {}", self.temporary.display()))?;
        if let Err(error) = file.write_all(text.as_bytes()) {
            let _ = fs::remove_file(&self.temporary);
            return Err(error)
                .with_context(|| format!("could not write {}", self.temporary.display()));
        }
        drop(file);

        if let Err(error) = fs::rename(&self.temporary, &self.output) {
            let _ = fs::remove_file(&self.temporary);
            return Err(error).with_context(|| {
                format!(
                    "could not replace {} with {}",
                    self.output.display(),
                    self.temporary.display()
                )
            });
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
        let test_dir = std::env::temp_dir().join(format!("music-test-{}", std::process::id()));
        let _ = fs::create_dir_all(&test_dir);
        let output = test_dir.join("test-conky-music.txt");
        let temporary = test_dir.join("test-conky-music.txt.tmp");

        let mut writer = OutputWriter::with_paths(output.clone(), temporary.clone()).unwrap();
        writer.write("Test Track").unwrap();
        let read = fs::read_to_string(&output).unwrap();
        assert_eq!(read, "Test Track");

        // Verify deduplication: writing same string is a no-op
        writer.write("Test Track").unwrap();
        assert_eq!(fs::read_to_string(&output).unwrap(), "Test Track");

        // Overwrite
        writer.write("New Track").unwrap();
        assert_eq!(fs::read_to_string(&output).unwrap(), "New Track");

        let _ = fs::remove_dir_all(&test_dir);
    }
}
