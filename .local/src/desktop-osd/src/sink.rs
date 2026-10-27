use std::collections::HashMap;
use std::path::Path;
use std::process::Command;

use serde::Deserialize;

use crate::osd::{send_dunst_notification, NotificationSpec};

const NOTIFICATION_ID: u32 = 2594;

#[derive(Debug, Clone, Deserialize)]
pub struct PulsePort {
    pub name: String,
    pub description: Option<String>,
    #[serde(default)]
    pub availability: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct PulseSink {
    pub name: String,
    pub description: Option<String>,
    pub active_port: Option<String>,
    #[serde(default)]
    pub ports: Vec<PulsePort>,
    #[serde(default)]
    pub properties: HashMap<String, serde_json::Value>,
}

#[derive(Debug, Clone)]
pub struct SinkInfo {
    pub name: String,
    pub description: String,
    pub icon: &'static str,
}

pub fn get_port_icon(description: &str) -> &'static str {
    let lower = description.to_lowercase();
    if lower.contains("headphone") || lower.contains("headset") {
        "audio-headphones"
    } else if lower.contains("speaker") || lower.contains("line") {
        "audio-speakers"
    } else {
        "audio-volume-high"
    }
}

pub fn get_sinks() -> Vec<PulseSink> {
    let out = match Command::new("pactl").args(["-f", "json", "list", "sinks"]).output() {
        Ok(o) if o.status.success() => o.stdout,
        _ => return Vec::new(),
    };
    serde_json::from_slice(&out).unwrap_or_default()
}

pub fn get_default_sink_name() -> Option<String> {
    let out = Command::new("pactl").arg("get-default-sink").output().ok()?;
    if out.status.success() {
        let name = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !name.is_empty() {
            return Some(name);
        }
    }
    None
}

pub fn get_sink_inputs() -> Vec<String> {
    let out = match Command::new("pactl").args(["list", "short", "sink-inputs"]).output() {
        Ok(o) if o.status.success() => String::from_utf8_lossy(&o.stdout).to_string(),
        _ => return Vec::new(),
    };

    out.lines()
        .filter_map(|line| {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if !parts.is_empty() && parts[0].chars().all(|c| c.is_ascii_digit()) {
                Some(parts[0].to_string())
            } else {
                None
            }
        })
        .collect()
}

pub fn unmute_alsa_port(target_port: &str, card: &str) {
    let card_arg = if card.is_empty() { "0" } else { card };
    let _ = Command::new("amixer").args(["-c", card_arg, "sset", "Master", "100%", "unmute"]).output();
    let lower = target_port.to_lowercase();
    if lower.contains("headphone") {
        let _ = Command::new("amixer").args(["-c", card_arg, "sset", "Headphone", "100%", "unmute"]).output();
    } else if lower.contains("speaker") || lower.contains("line") {
        let _ = Command::new("amixer").args(["-c", card_arg, "sset", "Front", "100%", "unmute"]).output();
    }
}

fn extract_alsa_card(sink: &PulseSink) -> String {
    match sink.properties.get("alsa.card") {
        Some(serde_json::Value::String(s)) => s.clone(),
        Some(serde_json::Value::Number(n)) => n.to_string(),
        _ => "0".to_string(),
    }
}

pub fn toggle_audio_sink(_runtime_dir: &Path) -> Result<SinkInfo, String> {
    let sinks = get_sinks();
    if sinks.is_empty() {
        return Err("No audio sinks available".to_string());
    }

    let default_name = get_default_sink_name().unwrap_or_else(|| sinks[0].name.clone());

    if sinks.len() > 1 {
        // Multi-sink setup: cycle through available sinks
        let cur_idx = sinks.iter().position(|s| s.name == default_name).unwrap_or(0);
        let next_idx = (cur_idx + 1) % sinks.len();
        let target = &sinks[next_idx];

        let status = Command::new("pactl")
            .args(["set-default-sink", &target.name])
            .status()
            .map_err(|e| format!("Failed to set default sink: {e}"))?;

        if !status.success() {
            return Err("pactl set-default-sink failed".to_string());
        }

        // Migrate active audio streams
        for stream_id in get_sink_inputs() {
            let _ = Command::new("pactl").args(["move-sink-input", &stream_id, &target.name]).output();
        }

        let alsa_card = extract_alsa_card(target);
        let target_port = target.active_port.as_deref().unwrap_or("");
        unmute_alsa_port(target_port, &alsa_card);

        let desc = target.description.clone().unwrap_or_else(|| target.name.clone());
        let icon = get_port_icon(&desc);

        let info = SinkInfo {
            name: target.name.clone(),
            description: desc.clone(),
            icon,
        };

        let spec = NotificationSpec {
            app_name: "Audio",
            id: NOTIFICATION_ID,
            title: "Audio Output Changed",
            body: &desc,
            icon,
            value: None,
            stack_tag: "audio-sink",
            timeout_ms: 1500,
        };
        send_dunst_notification(&spec);

        Ok(info)
    } else {
        // Single sink setup: cycle through available output ports (e.g. Headphones vs Line Out / Speakers)
        let sink = &sinks[0];
        if sink.ports.len() > 1 {
            let cur_port_name = sink.active_port.as_deref().unwrap_or("");
            let cur_idx = sink.ports.iter().position(|p| p.name == cur_port_name).unwrap_or(0);
            let next_idx = (cur_idx + 1) % sink.ports.len();
            let target_port = &sink.ports[next_idx];

            let status = Command::new("pactl")
                .args(["set-sink-port", &sink.name, &target_port.name])
                .status()
                .map_err(|e| format!("Failed to set sink port: {e}"))?;

            if !status.success() {
                return Err("pactl set-sink-port failed".to_string());
            }

            let alsa_card = extract_alsa_card(sink);
            unmute_alsa_port(&target_port.name, &alsa_card);

            let desc = target_port.description.clone().unwrap_or_else(|| target_port.name.clone());
            let icon = get_port_icon(&desc);

            let info = SinkInfo {
                name: format!("{}:{}", sink.name, target_port.name),
                description: desc.clone(),
                icon,
            };

            let spec = NotificationSpec {
                app_name: "Audio",
                id: NOTIFICATION_ID,
                title: "Audio Output Changed",
                body: &desc,
                icon,
                value: None,
                stack_tag: "audio-sink",
                timeout_ms: 1500,
            };
            send_dunst_notification(&spec);

            Ok(info)
        } else {
            let desc = sink.description.clone().unwrap_or_else(|| sink.name.clone());
            let icon = get_port_icon(&desc);
            let info = SinkInfo {
                name: sink.name.clone(),
                description: desc.clone(),
                icon,
            };

            let spec = NotificationSpec {
                app_name: "Audio",
                id: NOTIFICATION_ID,
                title: "Audio Output",
                body: "Only one audio output available",
                icon,
                value: None,
                stack_tag: "audio-sink",
                timeout_ms: 1500,
            };
            send_dunst_notification(&spec);

            Ok(info)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_port_icons() {
        assert_eq!(get_port_icon("Headphones (Built-in Audio)"), "audio-headphones");
        assert_eq!(get_port_icon("USB Audio Headset"), "audio-headphones");
        assert_eq!(get_port_icon("Line Out Speakers"), "audio-speakers");
        assert_eq!(get_port_icon("Generic HDMI Output"), "audio-volume-high");
    }

    #[test]
    fn test_parse_pulse_sink_json() {
        let json_data = r#"[{
            "index": 56,
            "name": "alsa_output.test.analog-stereo",
            "description": "Test Audio",
            "active_port": "analog-output-headphones",
            "ports": [
                {"name": "analog-output-lineout", "description": "Line Out"},
                {"name": "analog-output-headphones", "description": "Headphones"}
            ],
            "properties": {"alsa.card": "0"}
        }]"#;

        let sinks: Vec<PulseSink> = serde_json::from_str(json_data).unwrap();
        assert_eq!(sinks.len(), 1);
        assert_eq!(sinks[0].ports.len(), 2);
        assert_eq!(sinks[0].active_port.as_deref(), Some("analog-output-headphones"));
        assert_eq!(extract_alsa_card(&sinks[0]), "0");
    }
}
