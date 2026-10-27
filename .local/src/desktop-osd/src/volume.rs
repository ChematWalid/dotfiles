use std::path::Path;
use std::process::Command;
use std::time::Duration;

use crate::lock::FileLock;
use crate::osd::{dispatch_rate_limited, NotificationSpec};

const NOTIFICATION_ID: u32 = 2593;

#[derive(Debug, PartialEq, Eq)]
pub enum VolumeAction {
    Up(u32),
    Down(u32),
    Mute,
    MicMute,
    Get,
}

#[derive(Debug, Clone)]
pub struct VolumeState {
    pub volume: u32,
    pub is_muted: bool,
    pub is_mic: bool,
    pub raw_text: String,
}

pub fn parse_volume_output(output: &str, is_mic: bool) -> VolumeState {
    let trimmed = output.trim();
    if trimmed.eq_ignore_ascii_case("muted") {
        VolumeState {
            volume: 0,
            is_muted: true,
            is_mic,
            raw_text: "Muted".to_string(),
        }
    } else {
        let digits: String = trimmed.chars().filter(|c| c.is_ascii_digit()).collect();
        let vol = digits.parse::<u32>().unwrap_or(0);
        VolumeState {
            volume: vol,
            is_muted: false,
            is_mic,
            raw_text: format!("{vol}%"),
        }
    }
}

pub fn get_icon_and_label(state: &VolumeState) -> (&'static str, String) {
    if state.is_mic {
        if state.is_muted {
            ("audio-input-microphone-muted", "Microphone: Muted".to_string())
        } else {
            ("audio-input-microphone", format!("Microphone: {}", state.raw_text))
        }
    } else if state.is_muted || state.volume == 0 {
        ("audio-volume-muted", "Muted".to_string())
    } else if state.volume >= 70 {
        ("audio-volume-high", state.raw_text.clone())
    } else if state.volume >= 30 {
        ("audio-volume-medium", state.raw_text.clone())
    } else {
        ("audio-volume-low", state.raw_text.clone())
    }
}

pub fn execute_volume_action(action: &VolumeAction, runtime_dir: &Path) -> Result<VolumeState, String> {
    let lock_path = runtime_dir.join("volume-osd.lock");
    let _lock = FileLock::try_acquire(&lock_path, Duration::from_millis(1500));

    let is_mic = matches!(action, VolumeAction::MicMute);

    let output = match action {
        VolumeAction::Up(step) => Command::new("pamixer")
            .args(["--unmute", "--allow-boost", "--increase", &step.to_string(), "--get-volume-human"])
            .output(),
        VolumeAction::Down(step) => Command::new("pamixer")
            .args(["--unmute", "--allow-boost", "--decrease", &step.to_string(), "--get-volume-human"])
            .output(),
        VolumeAction::Mute => Command::new("pamixer")
            .args(["-t", "--get-volume-human"])
            .output(),
        VolumeAction::MicMute => Command::new("pamixer")
            .args(["--default-source", "-t", "--get-volume-human"])
            .output(),
        VolumeAction::Get => Command::new("pamixer")
            .arg("--get-volume-human")
            .output(),
    };

    let raw = match output {
        Ok(out) if out.status.success() => String::from_utf8_lossy(&out.stdout).to_string(),
        _ => {
            // Fallback query
            let query = if is_mic {
                Command::new("pamixer").args(["--default-source", "--get-volume-human"]).output()
            } else {
                Command::new("pamixer").arg("--get-volume-human").output()
            };
            query
                .map(|q| String::from_utf8_lossy(&q.stdout).to_string())
                .unwrap_or_else(|_| "unknown".to_string())
        }
    };

    drop(_lock);

    let state = parse_volume_output(&raw, is_mic);

    if action != &VolumeAction::Get {
        let (icon, label) = get_icon_and_label(&state);
        let title = format!("Volume: {label}");
        let val = if state.is_muted { Some(0) } else { Some(state.volume) };

        let spec = NotificationSpec {
            app_name: "Volume",
            id: NOTIFICATION_ID,
            title: &title,
            body: "",
            icon,
            value: val,
            stack_tag: "volume",
            timeout_ms: 1200,
        };

        dispatch_rate_limited(&spec, runtime_dir, 60);
    }

    Ok(state)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_volume_muted() {
        let state = parse_volume_output("muted\n", false);
        assert!(state.is_muted);
        assert_eq!(state.volume, 0);
        let (icon, label) = get_icon_and_label(&state);
        assert_eq!(icon, "audio-volume-muted");
        assert_eq!(label, "Muted");
    }

    #[test]
    fn test_parse_volume_levels() {
        let high = parse_volume_output("85%\n", false);
        assert_eq!(high.volume, 85);
        let (icon_high, _) = get_icon_and_label(&high);
        assert_eq!(icon_high, "audio-volume-high");

        let med = parse_volume_output("45%\n", false);
        assert_eq!(med.volume, 45);
        let (icon_med, _) = get_icon_and_label(&med);
        assert_eq!(icon_med, "audio-volume-medium");

        let low = parse_volume_output("15%\n", false);
        assert_eq!(low.volume, 15);
        let (icon_low, _) = get_icon_and_label(&low);
        assert_eq!(icon_low, "audio-volume-low");
    }

    #[test]
    fn test_parse_mic_mute() {
        let mic_muted = parse_volume_output("muted", true);
        assert!(mic_muted.is_muted);
        let (icon, label) = get_icon_and_label(&mic_muted);
        assert_eq!(icon, "audio-input-microphone-muted");
        assert_eq!(label, "Microphone: Muted");

        let mic_on = parse_volume_output("100%", true);
        assert!(!mic_on.is_muted);
        let (icon, label) = get_icon_and_label(&mic_on);
        assert_eq!(icon, "audio-input-microphone");
        assert_eq!(label, "Microphone: 100%");
    }
}
