//! Atomic file writer for Conky desktop output.

use crate::config::output_paths;
use std::fs::{self, OpenOptions};
use std::io::Write;

pub fn write_output_atomic(text: &str) {
    let (output, temporary) = output_paths();
    let text = text.trim();
    if fs::read(&output).is_ok_and(|current| current == text.as_bytes()) {
        return;
    }

    if let Some(parent) = output.parent() {
        if fs::create_dir_all(parent).is_err() {
            return;
        }
    }

    let Ok(mut file) = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .open(&temporary)
    else {
        return;
    };
    if file.write_all(text.as_bytes()).is_ok() {
        drop(file);
        if fs::rename(&temporary, &output).is_err() {
            let _ = fs::remove_file(temporary);
        }
    } else {
        let _ = fs::remove_file(temporary);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_atomic_write() {
        let (output, _) = output_paths();
        write_output_atomic("Test Track");
        let read = fs::read_to_string(output).unwrap();
        assert_eq!(read, "Test Track");
        // Clean up
        write_output_atomic("");
    }
}
