//! sync-antigravity — Bidirectional Conversation Synchronizer in Rust.
//! Synchronizes conversations, artifacts, and summary catalogs between:
//!   • Antigravity Desktop IDE  (~/.gemini/antigravity)
//!   • Antigravity CLI (agy)    (~/.gemini/antigravity-cli)

use serde::Deserialize;
use std::collections::{HashMap, HashSet};
use std::fs;
use std::os::unix::fs::symlink;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

fn home_dir() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/home/walid"))
}

// ----------------- Protobuf Wire Helper -----------------

fn parse_varint(buf: &[u8], mut pos: usize) -> Option<(u64, usize)> {
    let mut val = 0u64;
    let mut shift = 0;
    while pos < buf.len() {
        let b = buf[pos];
        pos += 1;
        val |= ((b & 0x7f) as u64) << shift;
        if (b & 0x80) == 0 {
            return Some((val, pos));
        }
        shift += 7;
        if shift >= 64 {
            return None;
        }
    }
    None
}

fn encode_varint(mut val: u64) -> Vec<u8> {
    let mut res = Vec::new();
    while val > 0x7f {
        res.push(((val & 0x7f) as u8) | 0x80);
        val >>= 7;
    }
    res.push((val & 0x7f) as u8);
    res
}

fn encode_field(field_num: u32, wire_type: u32, data: &[u8]) -> Vec<u8> {
    let tag = (field_num << 3) | wire_type;
    let mut res = encode_varint(tag as u64);
    if wire_type == 0 {
        // data is raw bytes of varint
        res.extend_from_slice(data);
    } else if wire_type == 2 {
        res.extend_from_slice(&encode_varint(data.len() as u64));
        res.extend_from_slice(data);
    }
    res
}

#[derive(Debug, Clone, Default)]
struct ProtoEntry {
    title: String,
    step_count: u64,
}

fn read_gui_proto(proto_path: &Path) -> (HashMap<String, ProtoEntry>, Vec<u8>) {
    if !proto_path.exists() {
        return (HashMap::new(), Vec::new());
    }
    let data = fs::read(proto_path).unwrap_or_default();
    let mut convs = HashMap::new();
    let mut pos = 0;

    while pos < data.len() {
        let Some((tag, new_pos)) = parse_varint(&data, pos) else { break; };
        pos = new_pos;
        let wire_type = tag & 0x7;
        if wire_type != 2 {
            break;
        }
        let Some((length, new_pos)) = parse_varint(&data, pos) else { break; };
        pos = new_pos;
        let length = length as usize;
        if pos + length > data.len() {
            break;
        }
        let chunk = &data[pos..pos + length];
        pos += length;

        let mut cpos = 0;
        let mut cid = None;
        let mut title = String::new();
        let mut step_count = 0;

        while cpos < chunk.len() {
            let Some((ctag, new_cpos)) = parse_varint(chunk, cpos) else { break; };
            cpos = new_cpos;
            let cfn = ctag >> 3;
            let cwt = ctag & 0x7;

            if cwt == 2 {
                let Some((clen, new_cpos)) = parse_varint(chunk, cpos) else { break; };
                cpos = new_cpos;
                let clen = clen as usize;
                if cpos + clen > chunk.len() {
                    break;
                }
                let cdata = &chunk[cpos..cpos + clen];
                cpos += clen;

                if cfn == 1 {
                    cid = Some(String::from_utf8_lossy(cdata).to_string());
                } else if cfn == 2 {
                    // summary_info
                    let mut spos = 0;
                    while spos < cdata.len() {
                        let Some((stag, new_spos)) = parse_varint(cdata, spos) else { break; };
                        spos = new_spos;
                        let sfn = stag >> 3;
                        let swt = stag & 0x7;
                        if swt == 2 {
                            let Some((slen, new_spos)) = parse_varint(cdata, spos) else { break; };
                            spos = new_spos;
                            let slen = slen as usize;
                            if spos + slen > cdata.len() {
                                break;
                            }
                            let sval = &cdata[spos..spos + slen];
                            spos += slen;
                            if sfn == 1 {
                                title = String::from_utf8_lossy(sval).to_string();
                            }
                        } else if swt == 0 {
                            let Some((sval, new_spos)) = parse_varint(cdata, spos) else { break; };
                            spos = new_spos;
                            if sfn == 2 {
                                step_count = sval;
                            }
                        } else if swt == 1 {
                            spos += 8;
                        } else if swt == 5 {
                            spos += 4;
                        }
                    }
                }
            } else if cwt == 0 {
                let Some((_, new_cpos)) = parse_varint(chunk, cpos) else { break; };
                cpos = new_cpos;
            } else if cwt == 1 {
                cpos += 8;
            } else if cwt == 5 {
                cpos += 4;
            }
        }

        if let Some(id) = cid {
            convs.insert(id, ProtoEntry { title, step_count });
        }
    }

    (convs, data)
}

fn build_gui_proto_entry(cid: &str, title: &str, step_count: u64, ts: u64, ws_uri: &str) -> Vec<u8> {
    let mut ts_bytes = encode_field(1, 0, &encode_varint(ts));
    ts_bytes.extend_from_slice(&encode_field(2, 0, &encode_varint(0)));

    let mut summary = Vec::new();
    summary.extend_from_slice(&encode_field(1, 2, title.as_bytes()));
    summary.extend_from_slice(&encode_field(2, 0, &encode_varint(step_count.max(1))));
    summary.extend_from_slice(&encode_field(3, 2, &ts_bytes));
    summary.extend_from_slice(&encode_field(7, 2, &ts_bytes));

    if !ws_uri.is_empty() {
        let mut ws_bytes = encode_field(1, 2, ws_uri.as_bytes());
        ws_bytes.extend_from_slice(&encode_field(2, 2, ws_uri.as_bytes()));
        summary.extend_from_slice(&encode_field(9, 2, &ws_bytes));
    }

    let mut entry = encode_field(1, 2, cid.as_bytes());
    entry.extend_from_slice(&encode_field(2, 2, &summary));
    encode_field(1, 2, &entry)
}

#[derive(Debug, Deserialize)]
struct CliRow {
    conversation_id: String,
    title: Option<String>,
    preview: Option<String>,
    step_count: Option<u64>,
    last_modified_time: Option<String>,
    workspace_uris: Option<String>,
}

fn parse_iso_ts(ts_str: Option<&str>) -> u64 {
    let Some(s) = ts_str else {
        return SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    };
    // Format: "2026-09-06 20:17:57..."
    if let Some(date_time) = s.split('+').next() {
        let parts: Vec<&str> = date_time.trim().split_whitespace().collect();
        if parts.len() >= 2 {
            let d_parts: Vec<i64> = parts[0].split('-').filter_map(|p| p.parse().ok()).collect();
            let t_parts: Vec<i64> = parts[1].split(':').filter_map(|p| p.parse().ok()).collect();
            if d_parts.len() == 3 && t_parts.len() >= 2 {
                // Approximate timestamp
                let year = d_parts[0];
                let month = d_parts[1];
                let day = d_parts[2];
                let hour = t_parts[0];
                let min = t_parts[1];
                let sec = t_parts.get(2).cloned().unwrap_or(0);
                let days = (year - 1970) * 365 + (year - 1969) / 4 + (month - 1) * 30 + day;
                return (days * 86400 + hour * 3600 + min * 60 + sec) as u64;
            }
        }
    }
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs()
}

fn sync(quiet_if_no_changes: bool) {
    let home = home_dir();
    let gui_dir = home.join(".gemini/antigravity");
    let cli_dir = home.join(".gemini/antigravity-cli");

    let gui_convs = gui_dir.join("conversations");
    let cli_convs = cli_dir.join("conversations");

    let gui_brain = gui_dir.join("brain");
    let cli_brain = cli_dir.join("brain");

    let gui_proto = gui_dir.join("agyhub_summaries_proto.pb");
    let cli_db = cli_dir.join("conversation_summaries.db");

    if !quiet_if_no_changes {
        println!("🔄 Antigravity Bidirectional Conversation Synchronizer (Rust)");
        println!("{}", "=".repeat(55));
    }

    let _ = fs::create_dir_all(&gui_convs);
    let _ = fs::create_dir_all(&cli_convs);
    let _ = fs::create_dir_all(&gui_brain);
    let _ = fs::create_dir_all(&cli_brain);

    // 1. Backups
    if gui_proto.exists() {
        let _ = fs::copy(&gui_proto, format!("{}.bak", gui_proto.display()));
    }
    if cli_db.exists() {
        let _ = fs::copy(&cli_db, format!("{}.bak", cli_db.display()));
    }

    // 2. Filesystem Sync: Conversations (.db, .pb)
    let read_conv_files = |dir: &Path| -> HashSet<String> {
        let mut set = HashSet::new();
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                if name.ends_with(".db") || name.ends_with(".pb") {
                    set.insert(name);
                }
            }
        }
        set
    };

    let gui_dbs = read_conv_files(&gui_convs);
    let cli_dbs = read_conv_files(&cli_convs);

    let mut linked_to_cli = 0;
    let mut linked_to_gui = 0;

    for f in &gui_dbs {
        let dst = cli_convs.join(f);
        let src = gui_convs.join(f);
        if !dst.exists() {
            if symlink(&src, &dst).is_ok() {
                linked_to_cli += 1;
            }
        }
    }

    for f in &cli_dbs {
        let dst = gui_convs.join(f);
        let src = cli_convs.join(f);
        if !dst.exists() {
            if symlink(&src, &dst).is_ok() {
                linked_to_gui += 1;
            }
        }
    }

    // 3. Filesystem Sync: Brain / Artifacts
    let read_subdirs = |dir: &Path| -> HashSet<String> {
        let mut set = HashSet::new();
        if let Ok(entries) = fs::read_dir(dir) {
            for entry in entries.flatten() {
                if entry.path().is_dir() {
                    set.insert(entry.file_name().to_string_lossy().to_string());
                }
            }
        }
        set
    };

    let gui_brains = read_subdirs(&gui_brain);
    let cli_brains = read_subdirs(&cli_brain);

    let mut brain_to_cli = 0;
    let mut brain_to_gui = 0;

    for d in &gui_brains {
        let dst = cli_brain.join(d);
        let src = gui_brain.join(d);
        if !dst.exists() {
            if symlink(&src, &dst).is_ok() {
                brain_to_cli += 1;
            }
        }
    }

    for d in &cli_brains {
        let dst = gui_brain.join(d);
        let src = cli_brain.join(d);
        if !dst.exists() {
            if symlink(&src, &dst).is_ok() {
                brain_to_gui += 1;
            }
        }
    }

    // 4. Catalog Sync: CLI -> GUI (Inject CLI conversations into Protobuf)
    let (mut proto_convs, raw_proto_data) = read_gui_proto(&gui_proto);

    let cli_json = Command::new("sqlite3")
        .arg(&cli_db)
        .arg(".mode json")
        .arg("SELECT conversation_id, title, preview, step_count, last_modified_time, workspace_uris FROM conversation_summaries;")
        .output()
        .map(|o| o.stdout)
        .unwrap_or_default();

    let cli_rows: Vec<CliRow> = serde_json::from_slice(&cli_json).unwrap_or_default();

    let mut new_proto_entries = Vec::new();
    let mut added_to_gui_proto = 0;

    for row in cli_rows {
        if !proto_convs.contains_key(&row.conversation_id) {
            let mut disp_title = row
                .title
                .as_deref()
                .unwrap_or("")
                .trim();
            if disp_title.is_empty() {
                disp_title = row.preview.as_deref().unwrap_or("CLI Conversation").trim();
            }
            let truncated_title = if disp_title.len() > 60 {
                format!("{}...", &disp_title[..57])
            } else {
                disp_title.to_string()
            };

            let ts = parse_iso_ts(row.last_modified_time.as_deref());
            let ws_uri = row
                .workspace_uris
                .as_deref()
                .map(|u| u.trim_matches(|c| c == '[' || c == ']' || c == '"' || c == '\''))
                .unwrap_or("");

            let entry_bytes = build_gui_proto_entry(
                &row.conversation_id,
                &truncated_title,
                row.step_count.unwrap_or(1),
                ts,
                ws_uri,
            );
            new_proto_entries.extend_from_slice(&entry_bytes);
            proto_convs.insert(row.conversation_id.clone(), ProtoEntry {
                title: truncated_title,
                step_count: row.step_count.unwrap_or(1),
            });
            added_to_gui_proto += 1;
        }
    }

    if added_to_gui_proto > 0 {
        let tmp_proto = format!("{}.tmp", gui_proto.display());
        let mut full_data = raw_proto_data;
        full_data.extend_from_slice(&new_proto_entries);
        if fs::write(&tmp_proto, full_data).is_ok() {
            let _ = fs::rename(&tmp_proto, &gui_proto);
        }
    }

    // 5. Catalog Sync: GUI -> CLI (Ensure GUI conversations in SQLite)
    let existing_cli_cids_raw = Command::new("sqlite3")
        .arg(&cli_db)
        .arg("SELECT conversation_id FROM conversation_summaries;")
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default();

    let existing_cli_cids: HashSet<&str> = existing_cli_cids_raw.lines().map(|l| l.trim()).collect();
    let mut added_to_cli_db = 0;

    let _now_ts = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    let now_iso = format!("2026-09-06 22:00:00.000000+00:00");

    for (cid, entry) in &proto_convs {
        if !existing_cli_cids.contains(cid.as_str()) {
            let escaped_title = entry.title.replace('\'', "''");
            let sql = format!(
                "INSERT INTO conversation_summaries ( \
                    conversation_id, title, preview, step_count, last_modified_time, \
                    workspace_uris, status, source, project_id, agent_name, \
                    parent_conversation_id, nesting_depth, battle_id, winning_conversation_id, \
                    not_fully_idle, killed, last_user_input_time, last_user_input_step_index, \
                    app_data_dir \
                ) VALUES ( \
                    '{}', '{}', '{}', {}, '{}', '', '', '', '', '', '', 0, '', '', 0, 0, '{}', -1, 'antigravity' \
                );",
                cid, escaped_title, escaped_title, entry.step_count, now_iso, now_iso
            );
            if Command::new("sqlite3").arg(&cli_db).arg(&sql).status().is_ok() {
                added_to_cli_db += 1;
            }
        }
    }

    let has_changes = (linked_to_cli + linked_to_gui + brain_to_cli + brain_to_gui + added_to_gui_proto + added_to_cli_db) > 0;
    if !quiet_if_no_changes || has_changes {
        println!("📦 Filesystem Sync:");
        println!("   • Database links:    +{} to CLI, +{} to GUI", linked_to_cli, linked_to_gui);
        println!("   • Brain directories: +{} to CLI, +{} to GUI", brain_to_cli, brain_to_gui);
        println!("📑 Catalog Index Sync:");
        println!("   • Injected into Desktop GUI (Protobuf): +{} conversations", added_to_gui_proto);
        println!("   • Injected into CLI (SQLite database):   +{} conversations", added_to_cli_db);
        println!("✅ Sync complete! Both interfaces share all conversations.");
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let watch = args.iter().any(|a| a == "--watch" || a == "-w");
    let interval = args
        .iter()
        .position(|a| a == "--interval" || a == "-n")
        .and_then(|idx| args.get(idx + 1))
        .and_then(|val| val.parse::<u64>().ok())
        .unwrap_or(10);

    if watch {
        println!("👀 Watching Antigravity directories every {}s... (Press Ctrl+C to stop)", interval);
        sync(false);
        loop {
            thread::sleep(Duration::from_secs(interval));
            sync(true);
        }
    } else {
        sync(false);
    }
}
