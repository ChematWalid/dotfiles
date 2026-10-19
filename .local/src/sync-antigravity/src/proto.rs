//! Low-level Protobuf wire encoder and decoder for Antigravity hub summaries.

use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::Path;

pub fn parse_varint(buf: &[u8], mut pos: usize) -> Option<(u64, usize)> {
    let mut val = 0u64;
    let mut shift = 0;
    while pos < buf.len() {
        let b = buf[pos];
        pos += 1;
        if shift == 63 && b & 0xfe != 0 {
            return None;
        }
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

pub fn encode_varint(mut val: u64) -> Vec<u8> {
    let mut res = Vec::new();
    while val > 0x7f {
        res.push(((val & 0x7f) as u8) | 0x80);
        val >>= 7;
    }
    res.push((val & 0x7f) as u8);
    res
}

pub fn encode_field(field_num: u32, wire_type: u32, data: &[u8]) -> Vec<u8> {
    let tag = (field_num << 3) | wire_type;
    let mut res = encode_varint(tag as u64);
    if wire_type == 0 {
        res.extend_from_slice(data);
    } else if wire_type == 2 {
        res.extend_from_slice(&encode_varint(data.len() as u64));
        res.extend_from_slice(data);
    }
    res
}

#[derive(Debug, Clone, Default)]
pub struct ProtoEntry {
    pub title: String,
    pub step_count: u64,
    pub last_modified_unix: Option<u64>,
}

fn invalid_proto() -> io::Error {
    io::Error::new(
        io::ErrorKind::InvalidData,
        "Malformed Antigravity summary protobuf",
    )
}

fn take_varint(data: &[u8], position: &mut usize) -> io::Result<u64> {
    let (value, next) = parse_varint(data, *position).ok_or_else(invalid_proto)?;
    *position = next;
    Ok(value)
}

fn take_bytes<'a>(data: &'a [u8], position: &mut usize) -> io::Result<&'a [u8]> {
    let length = usize::try_from(take_varint(data, position)?).map_err(|_| invalid_proto())?;
    let end = position.checked_add(length).ok_or_else(invalid_proto)?;
    let bytes = data.get(*position..end).ok_or_else(invalid_proto)?;
    *position = end;
    Ok(bytes)
}

fn skip_field(data: &[u8], position: &mut usize, wire_type: u64) -> io::Result<()> {
    match wire_type {
        0 => {
            take_varint(data, position)?;
        }
        1 | 5 => {
            let size = if wire_type == 1 { 8 } else { 4 };
            let end = position.checked_add(size).ok_or_else(invalid_proto)?;
            if end > data.len() {
                return Err(invalid_proto());
            }
            *position = end;
        }
        2 => {
            take_bytes(data, position)?;
        }
        _ => return Err(invalid_proto()),
    }
    Ok(())
}

fn parse_summary(data: &[u8]) -> io::Result<ProtoEntry> {
    let mut entry = ProtoEntry::default();
    let mut position = 0;

    while position < data.len() {
        let tag = take_varint(data, &mut position)?;
        let field = tag >> 3;
        let wire_type = tag & 0x7;
        if field == 0 {
            return Err(invalid_proto());
        }

        match (field, wire_type) {
            (1, 2) => {
                entry.title =
                    String::from_utf8_lossy(take_bytes(data, &mut position)?).into_owned();
            }
            (2, 0) => entry.step_count = take_varint(data, &mut position)?,
            (3, 2) => {
                entry.last_modified_unix = parse_timestamp(take_bytes(data, &mut position)?);
            }
            (_, wire_type) => skip_field(data, &mut position, wire_type)?,
        }
    }

    Ok(entry)
}

fn parse_conversation(data: &[u8]) -> io::Result<Option<(String, ProtoEntry)>> {
    let mut conversation_id = None;
    let mut entry = ProtoEntry::default();
    let mut position = 0;

    while position < data.len() {
        let tag = take_varint(data, &mut position)?;
        let field = tag >> 3;
        let wire_type = tag & 0x7;
        if field == 0 {
            return Err(invalid_proto());
        }

        match (field, wire_type) {
            (1, 2) => {
                conversation_id =
                    Some(String::from_utf8_lossy(take_bytes(data, &mut position)?).into_owned());
            }
            (2, 2) => entry = parse_summary(take_bytes(data, &mut position)?)?,
            (_, wire_type) => skip_field(data, &mut position, wire_type)?,
        }
    }

    Ok(conversation_id.map(|id| (id, entry)))
}

pub fn read_gui_proto(proto_path: &Path) -> io::Result<(HashMap<String, ProtoEntry>, Vec<u8>)> {
    let data = match fs::read(proto_path) {
        Ok(data) => data,
        Err(error) if error.kind() == io::ErrorKind::NotFound => {
            return Ok((HashMap::new(), Vec::new()));
        }
        Err(error) => return Err(error),
    };

    let mut convs = HashMap::new();
    let mut pos = 0;

    while pos < data.len() {
        let tag = take_varint(&data, &mut pos)?;
        let field = tag >> 3;
        let wire_type = tag & 0x7;
        if field == 0 {
            return Err(invalid_proto());
        }
        if wire_type == 2 && field == 1 {
            if let Some((id, entry)) = parse_conversation(take_bytes(&data, &mut pos)?)? {
                convs.insert(id, entry);
            }
        } else {
            skip_field(&data, &mut pos, wire_type)?;
        }
    }

    Ok((convs, data))
}

fn parse_timestamp(data: &[u8]) -> Option<u64> {
    let mut pos = 0;
    let mut seconds = None;
    while pos < data.len() {
        let (tag, next) = parse_varint(data, pos)?;
        pos = next;
        let field = tag >> 3;
        match tag & 0x7 {
            0 => {
                let (value, next) = parse_varint(data, pos)?;
                pos = next;
                if field == 1 {
                    seconds = Some(value);
                }
            }
            1 => {
                pos = pos.checked_add(8)?;
                if pos > data.len() {
                    return None;
                }
            }
            2 => {
                let (length, next) = parse_varint(data, pos)?;
                pos = next.checked_add(usize::try_from(length).ok()?)?;
                if pos > data.len() {
                    return None;
                }
            }
            5 => {
                pos = pos.checked_add(4)?;
                if pos > data.len() {
                    return None;
                }
            }
            _ => return None,
        }
    }
    seconds
}

pub fn build_gui_proto_entry(
    cid: &str,
    title: &str,
    step_count: u64,
    ts: u64,
    ws_uri: &str,
) -> Vec<u8> {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_timestamp_from_summary_proto_entry() {
        let path = std::env::temp_dir().join(format!(
            "sync-antigravity-proto-test-{}.pb",
            std::process::id()
        ));
        let bytes = build_gui_proto_entry("conversation-id", "Example", 7, 1_234_567, "");
        fs::write(&path, bytes).unwrap();
        let (entries, _) = read_gui_proto(&path).unwrap();
        let _ = fs::remove_file(path);

        let entry = entries.get("conversation-id").unwrap();
        assert_eq!(entry.title, "Example");
        assert_eq!(entry.step_count, 7);
        assert_eq!(entry.last_modified_unix, Some(1_234_567));
    }
}
