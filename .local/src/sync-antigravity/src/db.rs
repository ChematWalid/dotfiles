//! SQLite interaction for CLI conversation database.

use serde::Deserialize;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
pub struct CliRow {
    pub conversation_id: String,
    pub title: Option<String>,
    pub preview: Option<String>,
    pub step_count: Option<u64>,
    pub last_modified_time: Option<String>,
    pub workspace_uris: Option<String>,
}

pub fn fetch_cli_rows(db_path: &Path) -> Vec<CliRow> {
    if !db_path.exists() {
        return Vec::new();
    }
    let sql = "SELECT json_group_array(json_object(\
        'conversation_id', conversation_id,\
        'title', title,\
        'preview', preview,\
        'step_count', step_count,\
        'last_modified_time', last_modified_time,\
        'workspace_uris', workspace_uris\
    )) FROM conversation_summaries;";

    let Ok(output) = Command::new("sqlite3")
        .args([db_path.to_str().unwrap(), sql])
        .output()
    else {
        return Vec::new();
    };

    let json_str = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&json_str).unwrap_or_default()
}

pub fn parse_iso_ts(ts_str: Option<&str>) -> u64 {
    let Some(s) = ts_str else {
        return SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();
    };
    if let Some(date_time) = s.split('+').next() {
        let parts: Vec<&str> = date_time.split_whitespace().collect();
        if parts.len() >= 2 {
            let d_parts: Vec<i64> = parts[0].split('-').filter_map(|p| p.parse().ok()).collect();
            let t_parts: Vec<i64> = parts[1].split(':').filter_map(|p| p.parse().ok()).collect();
            if d_parts.len() == 3 && t_parts.len() >= 2 {
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
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs()
}

pub fn insert_cli_row(
    db_path: &Path,
    cid: &str,
    title: &str,
    step_count: u64,
    created_at_iso: &str,
    last_mod_iso: &str,
    ws_uri: &str,
) {
    let title_escaped = title.replace('\'', "''");
    let ws_json = format!("[\"{}\"]", ws_uri.replace('\'', "''"));

    let insert_sql = format!(
        "INSERT OR IGNORE INTO conversation_summaries (\
            conversation_id, created_at, last_modified_time, title, preview, step_count, workspace_uris\
        ) VALUES (\
            '{}', '{}', '{}', '{}', '{}', {}, '{}'\
        );",
        cid, created_at_iso, last_mod_iso, title_escaped, title_escaped, step_count.max(1), ws_json
    );

    let _ = Command::new("sqlite3")
        .args([db_path.to_str().unwrap(), &insert_sql])
        .status();
}
