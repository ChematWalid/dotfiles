//! rofi-clipboard — High-performance Rofi Clipboard Picker with Large Previews powered by CopyQ.
//! Modular, maintainable architecture following rust-patterns.

mod card;
mod copyq;
mod rofi;
mod theme;

use anyhow::Result;
use card::Renderer;
use copyq::{fetch_items, select_and_paste};
use rofi::run_rofi;
use std::fs;
use theme::CACHE_DIR;

fn main() -> Result<()> {
    let _ = fs::create_dir_all(CACHE_DIR);

    let items = fetch_items()?;
    if items.is_empty() {
        return Ok(());
    }

    let renderer = Renderer::new();

    if let Some(idx) = run_rofi(&items, &renderer) {
        if idx < items.len() {
            select_and_paste(items[idx].i);
        }
    }

    Ok(())
}
