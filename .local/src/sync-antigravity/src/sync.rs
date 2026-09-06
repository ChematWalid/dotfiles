//! Synchronization engine across conversations, transcripts, artifacts, and catalogs.

use std::collections::HashSet;
use std::fs;
use std::os::unix::fs::symlink;

use crate::config::SyncPaths;
use crate::db::{fetch_cli_rows, insert_cli_row, parse_iso_ts};
use crate::proto::{build_gui_proto_entry, read_gui_proto};

pub fn run_sync(quiet_if_no_changes: bool) {
    let paths = SyncPaths::new();

    if !quiet_if_no_changes {
        println!("🔄 Antigravity Bidirectional Conversation Synchronizer (Rust)");
        println!("{}", "=".repeat(55));
    }

    let _ = fs::create_dir_all(&paths.gui_convs);
    let _ = fs::create_dir_all(&paths.cli_convs);
    let _ = fs::create_dir_all(&paths.gui_brain);
    let _ = fs::create_dir_all(&paths.cli_brain);

    // 1. Backups
    if paths.gui_proto.exists() {
        let _ = fs::copy(
            &paths.gui_proto,
            paths.gui_dir.join("agyhub_summaries_proto.pb.bak"),
        );
    }
    if paths.cli_db.exists() {
        let _ = fs::copy(
            &paths.cli_db,
            paths.cli_dir.join("conversation_summaries.db.bak"),
        );
    }

    // 2. Read GUI proto
    let (gui_entries, mut raw_proto) = read_gui_proto(&paths.gui_proto);

    // 3. Read CLI SQLite db
    let cli_rows = fetch_cli_rows(&paths.cli_db);

    let mut cli_map = HashSet::new();
    let mut cli_row_map = Vec::new();
    for row in cli_rows {
        cli_map.insert(row.conversation_id.clone());
        cli_row_map.push(row);
    }

    let mut synced_to_cli = 0;
    let mut synced_to_gui = 0;

    // 4. GUI -> CLI
    for (cid, entry) in &gui_entries {
        if !cli_map.contains(cid) {
            let title = if entry.title.is_empty() {
                "Untitled Conversation"
            } else {
                &entry.title
            };
            let now_iso = "2026-09-06 20:00:00.000000+00:00";
            insert_cli_row(
                &paths.cli_db,
                cid,
                title,
                entry.step_count,
                now_iso,
                now_iso,
                "file:///home/walid/E/Documents",
            );
            synced_to_cli += 1;
        }
    }

    // 5. CLI -> GUI
    for row in &cli_row_map {
        if !gui_entries.contains_key(&row.conversation_id) {
            let title = row.title.as_deref().unwrap_or("Untitled Conversation");
            let step_count = row.step_count.unwrap_or(1);
            let ts = parse_iso_ts(row.last_modified_time.as_deref());
            let ws_uri = "file:///home/walid/E/Documents";

            let entry_bytes =
                build_gui_proto_entry(&row.conversation_id, title, step_count, ts, ws_uri);
            raw_proto.extend_from_slice(&entry_bytes);
            synced_to_gui += 1;
        }
    }

    if synced_to_gui > 0 && !raw_proto.is_empty() {
        let _ = fs::write(&paths.gui_proto, &raw_proto);
    }

    // 6. Brain / Transcripts / Artifacts mirroring
    let mut files_linked = 0;
    let all_cids: HashSet<String> = gui_entries.keys().chain(cli_map.iter()).cloned().collect();

    for cid in all_cids {
        let g_brain = paths.gui_brain.join(&cid);
        let c_brain = paths.cli_brain.join(&cid);

        if g_brain.exists() && !c_brain.exists() {
            let _ = symlink(&g_brain, &c_brain);
            files_linked += 1;
        } else if c_brain.exists() && !g_brain.exists() {
            let _ = symlink(&c_brain, &g_brain);
            files_linked += 1;
        }

        let g_conv = paths.gui_convs.join(format!("{}.json", cid));
        let c_conv = paths.cli_convs.join(format!("{}.json", cid));

        if g_conv.exists() && !c_conv.exists() {
            let _ = symlink(&g_conv, &c_conv);
            files_linked += 1;
        } else if c_conv.exists() && !g_conv.exists() {
            let _ = symlink(&c_conv, &g_conv);
            files_linked += 1;
        }
    }

    if !quiet_if_no_changes || synced_to_cli > 0 || synced_to_gui > 0 || files_linked > 0 {
        let total = gui_entries.len().max(cli_map.len());
        println!("✨ Sync Complete:");
        println!("   • Total active conversations : {}", total);
        println!("   • Synced to CLI DB          : +{}", synced_to_cli);
        println!("   • Synced to GUI Proto       : +{}", synced_to_gui);
        println!("   • Files/Artifacts Linked    : +{}", files_linked);
    }
}
