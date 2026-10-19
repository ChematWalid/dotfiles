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
    let args: Vec<String> = env::args().collect();
    let is_quiet = args.iter().any(|a| a == "--quiet" || a == "-q");
    let dry_run = args.iter().any(|a| a == "--dry-run");

    if let Err(error) = sync::run_sync(is_quiet, dry_run) {
        eprintln!("Antigravity sync failed: {error}");
        std::process::exit(1);
    }
}
