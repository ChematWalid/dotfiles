use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::Duration;

use crate::lock::FileLock;
use crate::osd::{dispatch_rate_limited, NotificationSpec};

const NOTIFICATION_ID: u32 = 9994;

#[derive(Debug, PartialEq, Eq)]
pub enum BrightnessAction {
    Up(u32),
    Down(u32),
    Get,
}

pub fn has_backlight_device() -> bool {
    if let Ok(entries) = fs::read_dir("/sys/class/backlight") {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                return true;
            }
        }
    }
    false
}

pub fn parse_brightnessctl_output(machine_format: &str) -> Option<u32> {
    // Format: device,class,current,percent,max
    let parts: Vec<&str> = machine_format.trim().split(',').collect();
    if parts.len() >= 4 {
        let percent_str = parts[3].trim_end_matches('%');
        return percent_str.parse::<u32>().ok();
    }
    None
}

pub fn parse_ddcutil_output(brief_format: &str) -> Option<u32> {
    // Format: VCP 10 C 60 100
    let parts: Vec<&str> = brief_format.split_whitespace().collect();
    if parts.len() >= 4 {
        return parts[3].parse::<u32>().ok();
    }
    None
}

pub fn execute_brightness_action(action: &BrightnessAction, runtime_dir: &Path) -> Result<u32, String> {
    let lock_path = runtime_dir.join("brightness-osd.lock");
    let _lock = FileLock::try_acquire(&lock_path, Duration::from_millis(2500));

    let use_backlight = has_backlight_device();

    let bright = if use_backlight {
        match action {
            BrightnessAction::Up(step) => {
                let _ = Command::new("brightnessctl")
                    .args(["--class", "backlight", "set", &format!("{step}%+")])
                    .output();
            }
            BrightnessAction::Down(step) => {
                let _ = Command::new("brightnessctl")
                    .args(["--class", "backlight", "set", &format!("{step}%-")])
                    .output();
            }
            BrightnessAction::Get => {}
        }

        let out = Command::new("brightnessctl")
            .args(["--class", "backlight", "-m"])
            .output()
            .map_err(|e| format!("Failed to run brightnessctl: {e}"))?;
        let text = String::from_utf8_lossy(&out.stdout);
        parse_brightnessctl_output(&text).ok_or_else(|| "Failed to parse brightnessctl output".to_string())?
    } else {
        // Desktop monitor using DDC/CI
        match action {
            BrightnessAction::Up(step) => {
                let _ = Command::new("ddcutil")
                    .args([
                        "--skip-ddc-checks",
                        "--noverify",
                        "--mccs",
                        "2.2",
                        "--display",
                        "1",
                        "setvcp",
                        "10",
                        "+",
                        &step.to_string(),
                    ])
                    .output();
            }
            BrightnessAction::Down(step) => {
                let _ = Command::new("ddcutil")
                    .args([
                        "--skip-ddc-checks",
                        "--noverify",
                        "--mccs",
                        "2.2",
                        "--display",
                        "1",
                        "setvcp",
                        "10",
                        "-",
                        &step.to_string(),
                    ])
                    .output();
            }
            BrightnessAction::Get => {}
        }

        let out = Command::new("ddcutil")
            .args([
                "--skip-ddc-checks",
                "--mccs",
                "2.2",
                "--display",
                "1",
                "getvcp",
                "10",
                "--brief",
            ])
            .output()
            .map_err(|e| format!("Failed to run ddcutil: {e}"))?;
        let text = String::from_utf8_lossy(&out.stdout);
        parse_ddcutil_output(&text).ok_or_else(|| "Failed to parse ddcutil output".to_string())?
    };

    drop(_lock);

    if action != &BrightnessAction::Get {
        let title = format!("󰃠  Brightness: {bright}%");
        let spec = NotificationSpec {
            app_name: "brightness",
            id: NOTIFICATION_ID,
            title: &title,
            body: "",
            icon: "display-brightness",
            value: Some(bright),
            stack_tag: "brightness",
            timeout_ms: 1200,
        };

        dispatch_rate_limited(&spec, runtime_dir, 60);
    }

    Ok(bright)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_brightnessctl() {
        let sample = "intel_backlight,backlight,1200,60%,2000\n";
        assert_eq!(parse_brightnessctl_output(sample), Some(60));
    }

    #[test]
    fn test_parse_ddcutil() {
        let sample = "VCP 10 C 75 100\n";
        assert_eq!(parse_ddcutil_output(sample), Some(75));
    }
}
