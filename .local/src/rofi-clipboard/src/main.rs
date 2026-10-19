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
use theme::cache_dir;

fn main() -> Result<()> {
    let cache_dir = cache_dir()?;

    let items = fetch_items(&cache_dir)?;
    if items.is_empty() {
        return Ok(());
    }

    let renderer = Renderer::new(cache_dir.clone())?;

    if let Some(idx) = run_rofi(&items, &renderer, &cache_dir)? {
        if idx < items.len() {
            select_and_paste(items[idx].i)?;
        }
    }

    Ok(())
}
