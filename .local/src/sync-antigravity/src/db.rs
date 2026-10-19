//! SQLite interaction for the Antigravity CLI conversation database.

use serde::Deserialize;
use std::error::Error;
use std::io;
use std::os::unix::fs::PermissionsExt;
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

pub fn fetch_cli_rows(db_path: &Path) -> Result<Vec<CliRow>, Box<dyn Error>> {
    if !db_path.exists() {
        return Err(io::Error::new(
            io::ErrorKind::NotFound,
            format!(
                "Antigravity CLI database does not exist: {}",
                db_path.display()
            ),
        )
        .into());
    }

    let sql = "SELECT COALESCE(json_group_array(json_object(\
        'conversation_id', conversation_id,\
        'title', title,\
        'preview', preview,\
        'step_count', step_count,\
        'last_modified_time', last_modified_time,\
        'workspace_uris', workspace_uris\
    )), '[]') FROM conversation_summaries;";

    let output = Command::new("sqlite3").arg(db_path).arg(sql).output()?;
    if !output.status.success() {
        return Err(io::Error::other(format!(
            "Could not read Antigravity CLI database: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ))
        .into());
    }

    let rows = serde_json::from_slice::<Vec<CliRow>>(&output.stdout)?;
    Ok(rows)
}

/// Parse a SQLite/ISO-8601 date-time into Unix seconds. Values without an
/// explicit timezone are interpreted as UTC, matching Antigravity's DB data.
pub fn parse_iso_ts(ts_str: Option<&str>) -> u64 {
    let Some(value) = ts_str else {
        return now_unix_seconds();
    };

    parse_iso_ts_inner(value).unwrap_or_else(now_unix_seconds)
}

fn parse_iso_ts_inner(value: &str) -> Option<u64> {
    let value = value.trim();
    let split = value.find(['T', ' '])?;
    let date = &value[..split];
    let time_and_zone = &value[split + 1..];

    let mut date_parts = date.split('-');
    let year = date_parts.next()?.parse::<i64>().ok()?;
    let month = date_parts.next()?.parse::<u32>().ok()?;
    let day = date_parts.next()?.parse::<u32>().ok()?;
    if date_parts.next().is_some() || !(1..=9999).contains(&year) || !(1..=12).contains(&month) {
        return None;
    }
    let leap_year = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    let days_in_month = match month {
        2 if leap_year => 29,
        2 => 28,
        4 | 6 | 9 | 11 => 30,
        _ => 31,
    };
    if day == 0 || day > days_in_month {
        return None;
    }

    let zone_index = time_and_zone
        .char_indices()
        .find_map(|(index, ch)| matches!(ch, 'Z' | '+' | '-').then_some(index));
    let (clock, zone) = zone_index
        .map(|index| (&time_and_zone[..index], &time_and_zone[index..]))
        .unwrap_or((time_and_zone, ""));
    let mut clock_parts = clock.split(':');
    let hour = clock_parts.next()?.parse::<i64>().ok()?;
    let minute = clock_parts.next()?.parse::<i64>().ok()?;
    let second_text = clock_parts.next()?;
    let (whole_second, fraction) = second_text.split_once('.').unwrap_or((second_text, ""));
    let second = whole_second.parse::<i64>().ok()?;
    if clock_parts.next().is_some()
        || !(0..=23).contains(&hour)
        || !(0..=59).contains(&minute)
        || !(0..=60).contains(&second)
        || (second_text.contains('.')
            && (fraction.is_empty() || !fraction.bytes().all(|b| b.is_ascii_digit())))
    {
        return None;
    }

    let timezone_offset = parse_timezone_offset(zone)?;
    let days = days_from_civil(year, month, day);
    let unix = days
        .checked_mul(86_400)?
        .checked_add(hour * 3_600 + minute * 60 + second)?
        .checked_sub(timezone_offset)?;
    u64::try_from(unix.max(0)).ok()
}

fn parse_timezone_offset(zone: &str) -> Option<i64> {
    if zone.is_empty() || zone == "Z" || zone == "z" {
        return Some(0);
    }
    let sign = match zone.as_bytes().first()? {
        b'+' => 1,
        b'-' => -1,
        _ => return None,
    };
    let mut parts = zone[1..].split(':');
    let hours = parts.next()?.parse::<i64>().ok()?;
    let minutes = parts.next()?.parse::<i64>().ok()?;
    if parts.next().is_some() || !(0..=23).contains(&hours) || !(0..=59).contains(&minutes) {
        return None;
    }
    Some(sign * (hours * 3_600 + minutes * 60))
}

// Howard Hinnant's proleptic Gregorian conversion, returning days from
// 1970-01-01. Inputs are validated by parse_iso_ts_inner.
fn days_from_civil(year: i64, month: u32, day: u32) -> i64 {
    let year = year - i64::from(month <= 2);
    let era = year.div_euclid(400);
    let year_of_era = year - era * 400;
    let month = i64::from(month);
    let day_of_year = (153 * (month + if month > 2 { -3 } else { 9 }) + 2) / 5 + i64::from(day) - 1;
    let day_of_era = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year;
    era * 146_097 + day_of_era - 719_468
}

fn now_unix_seconds() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default()
}

fn sql_quote(value: &str) -> Result<String, io::Error> {
    if value.contains('\0') {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "SQLite text values cannot contain NUL bytes",
        ));
    }
    Ok(format!("'{}'", value.replace('\'', "''")))
}

#[cfg(test)]
pub fn insert_cli_row(
    db_path: &Path,
    cid: &str,
    title: &str,
    step_count: u64,
    last_modified_unix: Option<u64>,
) -> Result<bool, Box<dyn Error>> {
    Ok(insert_cli_rows(db_path, &[(cid, title, step_count, last_modified_unix)])? == 1)
}

pub fn insert_cli_rows(
    db_path: &Path,
    rows: &[(&str, &str, u64, Option<u64>)],
) -> Result<usize, Box<dyn Error>> {
    if rows.is_empty() {
        return Ok(0);
    }

    let workspace_uris = sql_quote("[]")?;
    let mut sql = String::from("PRAGMA busy_timeout=5000;\nBEGIN IMMEDIATE;\n");
    for (cid, title, step_count, last_modified_unix) in rows {
        let cid = sql_quote(cid)?;
        let title = sql_quote(title)?;
        let step_count = step_count.max(&1);
        let timestamp = last_modified_unix
            .map(|seconds| format!("strftime('%Y-%m-%d %H:%M:%f+00:00', {seconds}, 'unixepoch')"))
            .unwrap_or_else(|| "strftime('%Y-%m-%d %H:%M:%f+00:00', 'now')".to_owned());
        sql.push_str(&format!(
            "INSERT OR IGNORE INTO conversation_summaries (\
                conversation_id, title, preview, step_count, last_modified_time, \
                workspace_uris, last_user_input_time\
            ) VALUES (\
                {cid}, {title}, {title}, {step_count}, {timestamp}, {workspace_uris}, {timestamp}\
            ); SELECT changes();\n"
        ));
    }
    sql.push_str("COMMIT;\n");

    let output = Command::new("sqlite3")
        .arg("-bail")
        .arg(db_path)
        .arg(sql)
        .output()?;
    if !output.status.success() {
        return Err(io::Error::other(format!(
            "Could not insert Antigravity conversations: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ))
        .into());
    }
    std::fs::set_permissions(db_path, std::fs::Permissions::from_mode(0o600))?;
    let changes = String::from_utf8(output.stdout)?;
    let mut result_lines = changes.lines();
    if result_lines
        .next()
        .and_then(|line| line.parse::<u64>().ok())
        != Some(5_000)
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "SQLite did not return the configured busy timeout",
        )
        .into());
    }
    let mut inserted = 0;
    let mut statements = 0;
    for line in result_lines {
        inserted += line.parse::<usize>()?;
        statements += 1;
    }
    if statements != rows.len() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "SQLite returned an unexpected number of insert results",
        )
        .into());
    }
    Ok(inserted)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_iso_timestamp_and_timezone() {
        assert_eq!(parse_iso_ts(Some("1970-01-01 00:00:00+00:00")), 0);
        assert_eq!(parse_iso_ts(Some("1970-01-01T01:00:00+01:00")), 0);
        assert_eq!(
            parse_iso_ts(Some("2026-10-19 02:03:04.123456Z")),
            1_792_375_384
        );
    }

    #[test]
    fn inserts_using_current_cli_schema_and_escapes_text() {
        let path = std::env::temp_dir().join(format!(
            "sync-antigravity-test-{}-{}.db",
            std::process::id(),
            now_unix_seconds()
        ));
        let schema = "CREATE TABLE conversation_summaries (\
            conversation_id TEXT PRIMARY KEY, title TEXT NOT NULL DEFAULT '', \
            preview TEXT NOT NULL DEFAULT '', step_count INTEGER NOT NULL DEFAULT 0, \
            last_modified_time DATETIME NOT NULL, workspace_uris TEXT NOT NULL, \
            last_user_input_time DATETIME NOT NULL\
        );";
        let created = Command::new("sqlite3")
            .arg(&path)
            .arg(schema)
            .status()
            .unwrap();
        assert!(created.success());

        assert!(insert_cli_row(&path, "id-'quoted", "title ' quoted", 3, Some(0)).unwrap());
        assert!(!insert_cli_row(&path, "id-'quoted", "duplicate", 4, Some(1)).unwrap());
        let rows = fetch_cli_rows(&path).unwrap();
        assert_eq!(rows.len(), 1);
        assert_eq!(rows[0].conversation_id, "id-'quoted");
        assert_eq!(rows[0].title.as_deref(), Some("title ' quoted"));
        assert_eq!(rows[0].workspace_uris.as_deref(), Some("[]"));
        assert_eq!(
            std::fs::metadata(&path).unwrap().permissions().mode() & 0o777,
            0o600
        );

        let _ = std::fs::remove_file(path);
    }
}
