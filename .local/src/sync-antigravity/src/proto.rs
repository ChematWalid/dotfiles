//! Low-level Protobuf wire encoder and decoder for Antigravity hub summaries.

use std::collections::HashMap;
use std::fs;
use std::path::Path;

pub fn parse_varint(buf: &[u8], mut pos: usize) -> Option<(u64, usize)> {
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
}

pub fn read_gui_proto(proto_path: &Path) -> (HashMap<String, ProtoEntry>, Vec<u8>) {
    if !proto_path.exists() {
        return (HashMap::new(), Vec::new());
    }
    let data = fs::read(proto_path).unwrap_or_default();
    let mut convs = HashMap::new();
    let mut pos = 0;

    while pos < data.len() {
        let Some((tag, new_pos)) = parse_varint(&data, pos) else {
            break;
        };
        pos = new_pos;
        let wire_type = tag & 0x7;
        if wire_type != 2 {
            break;
        }
        let Some((length, new_pos)) = parse_varint(&data, pos) else {
            break;
        };
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
            let Some((ctag, new_cpos)) = parse_varint(chunk, cpos) else {
                break;
            };
            cpos = new_cpos;
            let cfn = ctag >> 3;
            let cwt = ctag & 0x7;

            if cwt == 2 {
                let Some((clen, new_cpos)) = parse_varint(chunk, cpos) else {
                    break;
                };
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
                    let mut spos = 0;
                    while spos < cdata.len() {
                        let Some((stag, new_spos)) = parse_varint(cdata, spos) else {
                            break;
                        };
                        spos = new_spos;
                        let sfn = stag >> 3;
                        let swt = stag & 0x7;
                        if swt == 2 {
                            let Some((slen, new_spos)) = parse_varint(cdata, spos) else {
                                break;
                            };
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
                            let Some((sval, new_spos)) = parse_varint(cdata, spos) else {
                                break;
                            };
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
                let Some((_, new_cpos)) = parse_varint(chunk, cpos) else {
                    break;
                };
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
