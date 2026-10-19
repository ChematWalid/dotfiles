//! Synchronization engine across conversations, transcripts, artifacts, and catalogs.

use std::collections::HashSet;
use std::error::Error;
use std::fs;
use std::os::unix::fs::symlink;
use std::os::unix::fs::PermissionsExt;

use crate::config::SyncPaths;
use crate::db::{fetch_cli_rows, insert_cli_rows, parse_iso_ts};
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

    // 1. Read GUI proto
    let (gui_entries, mut raw_proto) = read_gui_proto(&paths.gui_proto)?;

    // 2. Read CLI SQLite db
    let cli_rows = fetch_cli_rows(&paths.cli_db)?;

    let cli_ids: HashSet<&str> = cli_rows
        .iter()
        .map(|row| row.conversation_id.as_str())
        .collect();

    // 3. GUI -> CLI
    let imports: Vec<_> = gui_entries
        .iter()
        .filter(|(cid, _)| !cli_ids.contains(cid.as_str()))
        .map(|(cid, entry)| {
            let title = if entry.title.is_empty() {
                "Untitled Conversation"
            } else {
                entry.title.as_str()
            };
            (
                cid.as_str(),
                title,
                entry.step_count,
                entry.last_modified_unix,
            )
        })
        .collect();
    // 4. CLI -> GUI: collect missing entries before writes so backups are only
    // needed when either catalog will actually change.
    let cli_only_rows: Vec<_> = cli_rows
        .iter()
        .filter(|row| !gui_entries.contains_key(row.conversation_id.as_str()))
        .collect();
    let synced_to_gui = cli_only_rows.len();

    if !dry_run && (!imports.is_empty() || !cli_only_rows.is_empty()) {
        if paths.gui_proto.exists() {
            fs::copy(
                &paths.gui_proto,
                paths.gui_dir.join("agyhub_summaries_proto.pb.bak"),
            )?;
        }
        if paths.cli_db.exists() {
            let backup_path = paths.cli_dir.join("conversation_summaries.db.bak");
            fs::copy(&paths.cli_db, &backup_path)?;
            fs::set_permissions(&backup_path, fs::Permissions::from_mode(0o600))?;
        }
    }

    let synced_to_cli = if dry_run {
        imports.len()
    } else {
        insert_cli_rows(&paths.cli_db, &imports)?
    };

    for row in cli_only_rows {
        let title = row.title.as_deref().unwrap_or("Untitled Conversation");
        let step_count = row.step_count.unwrap_or(1);
        let ts = parse_iso_ts(row.last_modified_time.as_deref());
        let ws_uri = "file:///home/walid/E/Documents";

        let entry_bytes =
            build_gui_proto_entry(&row.conversation_id, title, step_count, ts, ws_uri);
        raw_proto.extend_from_slice(&entry_bytes);
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

    // 5. Brain / Transcripts / Artifacts mirroring
    let mut files_linked = 0;
    let gui_ids = gui_entries.keys().map(String::as_str);
    let cli_only_ids = cli_rows.iter().filter_map(|row| {
        let cid = row.conversation_id.as_str();
        (!gui_entries.contains_key(cid)).then_some(cid)
    });

    for cid in gui_ids.chain(cli_only_ids) {
        let g_brain = paths.gui_brain.join(cid);
        let c_brain = paths.cli_brain.join(cid);

        if g_brain.exists() && !c_brain.exists() {
            if dry_run || symlink(&g_brain, &c_brain).is_ok() {
                files_linked += 1;
            }
        } else if c_brain.exists()
            && !g_brain.exists()
            && (dry_run || symlink(&c_brain, &g_brain).is_ok())
        {
            files_linked += 1;
        }

        let filename = format!("{cid}.json");
        let g_conv = paths.gui_convs.join(&filename);
        let c_conv = paths.cli_convs.join(filename);

        if g_conv.exists() && !c_conv.exists() {
            if dry_run || symlink(&g_conv, &c_conv).is_ok() {
                files_linked += 1;
            }
        } else if c_conv.exists()
            && !g_conv.exists()
            && (dry_run || symlink(&c_conv, &g_conv).is_ok())
        {
            files_linked += 1;
        }
    }

    if !quiet_if_no_changes || synced_to_cli > 0 || synced_to_gui > 0 || files_linked > 0 {
        let total = gui_entries.len().max(cli_ids.len());
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
