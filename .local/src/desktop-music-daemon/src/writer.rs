//! Atomic file writer for Conky desktop output.

use crate::config::{OUTPUT_FILE, TMP_FILE};
use std::fs;

pub fn write_output_atomic(text: &str) {
    let _ = fs::write(TMP_FILE, text.trim()).and_then(|_| fs::rename(TMP_FILE, OUTPUT_FILE));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_atomic_write() {
        write_output_atomic("Test Track");
        let read = fs::read_to_string(OUTPUT_FILE).unwrap();
        assert_eq!(read, "Test Track");
        // Clean up
        write_output_atomic("");
    }
}
