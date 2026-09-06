//! sync-antigravity — Bidirectional Conversation Synchronizer in Rust.
//! Synchronizes conversations, artifacts, and summary catalogs between:
//!   • Antigravity Desktop IDE  (~/.gemini/antigravity)
//!   • Antigravity CLI (agy)    (~/.gemini/antigravity-cli)

mod config;
mod db;
mod proto;
mod sync;

use std::env;
use std::thread;
use std::time::Duration;

fn main() {
    let args: Vec<String> = env::args().collect();
    let is_watch = args.iter().any(|a| a == "--watch" || a == "-w");
    let is_quiet = args.iter().any(|a| a == "--quiet" || a == "-q");

    if is_watch {
        println!("👀 Starting Antigravity continuous sync (15s interval)...");
        loop {
            sync::run_sync(true);
            thread::sleep(Duration::from_secs(15));
        }
    } else {
        sync::run_sync(is_quiet);
    }
}
