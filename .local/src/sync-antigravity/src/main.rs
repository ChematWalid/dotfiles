//! sync-antigravity — Bidirectional Conversation Synchronizer in Rust.
//! Synchronizes conversations, artifacts, and summary catalogs between:
//!   • Antigravity Desktop IDE  (~/.gemini/antigravity)
//!   • Antigravity CLI (agy)    (~/.gemini/antigravity-cli)

mod config;
mod db;
mod proto;
mod sync;

use std::env;

fn main() {
    let (mut is_quiet, mut dry_run) = (false, false);
    for arg in env::args().skip(1) {
        match arg.as_str() {
            "--quiet" | "-q" => is_quiet = true,
            "--dry-run" => dry_run = true,
            _ => {}
        }
    }

    if let Err(error) = sync::run_sync(is_quiet, dry_run) {
        eprintln!("Antigravity sync failed: {error}");
        std::process::exit(1);
    }
}
