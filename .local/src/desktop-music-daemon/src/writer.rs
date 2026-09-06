//! Atomic file writer for Conky desktop output.

use crate::config::{OUTPUT_FILE, TMP_FILE};
use std::fs;

pub fn write_output_atomic(text: &str) {
    let _ = fs::write(TMP_FILE, text.trim()).and_then(|_| fs::rename(TMP_FILE, OUTPUT_FILE));
}
