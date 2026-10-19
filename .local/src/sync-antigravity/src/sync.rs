//! Synchronization engine across conversations, transcripts, artifacts, and catalogs.

use std::collections::HashSet;
use std::error::Error;
use std::fs;
use std::os::unix::fs::symlink;
use std::os::unix::fs::PermissionsExt;

use crate::config::SyncPaths;
use crate::db::{fetch_cli_rows, insert_cli_row, parse_iso_ts};
use crate::proto::{build_gui_proto_entry, read_gui_proto};

pub fn run_sync(quiet_if_no_changes: bool, dry_run: bool) -> Result<(), Box<dyn Error>> {
    let paths = SyncPaths::new();

    if !quiet_if_no_changes {
        println!("🔄 Antigravity Bidirectional Conversation Synchronizer (Rust)");
        println!("{}", "=".repeat(55));
    }

    if !dry_run {
        fs::create_dir_all(&paths.gui_convs)?;
        fs::create_dir_all(&paths.cli_convs)?;
        fs::create_dir_all(&paths.gui_brain)?;
        fs::create_dir_all(&paths.cli_brain)?;
    }

    // 1. Backups
    if !dry_run && paths.gui_proto.exists() {
        fs::copy(
            &paths.gui_proto,
            paths.gui_dir.join("agyhub_summaries_proto.pb.bak"),
        )?;
    }
    if !dry_run && paths.cli_db.exists() {
        let backup_path = paths.cli_dir.join("conversation_summaries.db.bak");
        fs::copy(&paths.cli_db, &backup_path)?;
        fs::set_permissions(&backup_path, fs::Permissions::from_mode(0o600))?;
    }

    // 2. Read GUI proto
    let (gui_entries, mut raw_proto) = read_gui_proto(&paths.gui_proto);

    // 3. Read CLI SQLite db
    let cli_rows = fetch_cli_rows(&paths.cli_db)?;

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
            if dry_run
                || insert_cli_row(
                    &paths.cli_db,
                    cid,
                    title,
                    entry.step_count,
                    entry.last_modified_unix,
                )?
            {
                synced_to_cli += 1;
            }
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

    if !dry_run && synced_to_gui > 0 && !raw_proto.is_empty() {
        let temp_path = paths.gui_proto.with_extension(format!(
            "pb.tmp.{}.{}",
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_nanos()
        ));
        fs::write(&temp_path, &raw_proto)?;
        fs::rename(&temp_path, &paths.gui_proto)?;
    }

    // 6. Brain / Transcripts / Artifacts mirroring
    let mut files_linked = 0;
    let all_cids: HashSet<String> = gui_entries.keys().chain(cli_map.iter()).cloned().collect();

    for cid in all_cids {
        let g_brain = paths.gui_brain.join(&cid);
        let c_brain = paths.cli_brain.join(&cid);

        if g_brain.exists() && !c_brain.exists() {
            if dry_run || symlink(&g_brain, &c_brain).is_ok() {
                files_linked += 1;
            }
        } else if c_brain.exists() && !g_brain.exists() {
            if dry_run || symlink(&c_brain, &g_brain).is_ok() {
                files_linked += 1;
            }
        }

        let g_conv = paths.gui_convs.join(format!("{}.json", cid));
        let c_conv = paths.cli_convs.join(format!("{}.json", cid));

        if g_conv.exists() && !c_conv.exists() {
            if dry_run || symlink(&g_conv, &c_conv).is_ok() {
                files_linked += 1;
            }
        } else if c_conv.exists() && !g_conv.exists() {
            if dry_run || symlink(&c_conv, &g_conv).is_ok() {
                files_linked += 1;
            }
        }
    }

    if !quiet_if_no_changes || synced_to_cli > 0 || synced_to_gui > 0 || files_linked > 0 {
        let total = gui_entries.len().max(cli_map.len());
        println!("✨ Sync {}:", if dry_run { "Preview" } else { "Complete" });
        println!("   • Total active conversations : {}", total);
        let prefix = if dry_run { "Would sync" } else { "Synced" };
        println!("   • {prefix} to CLI DB          : +{}", synced_to_cli);
        println!("   • {prefix} to GUI Proto       : +{}", synced_to_gui);
        let file_action = if dry_run {
            "Would link"
        } else {
            "Files/Artifacts Linked"
        };
        println!("   • {file_action}    : +{}", files_linked);
    }
    Ok(())
}
