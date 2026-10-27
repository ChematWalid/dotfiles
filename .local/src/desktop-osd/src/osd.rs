use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct NotificationSpec<'a> {
    pub app_name: &'a str,
    pub id: u32,
    pub title: &'a str,
    pub body: &'a str,
    pub icon: &'a str,
    pub value: Option<u32>,
    pub stack_tag: &'a str,
    pub timeout_ms: u32,
}

pub fn get_now_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_millis() as u64)
        .unwrap_or(0)
}

pub fn send_dunst_notification(spec: &NotificationSpec) -> bool {
    let mut cmd = Command::new("dunstify");
    cmd.args([
        "-a",
        spec.app_name,
        "-r",
        &spec.id.to_string(),
        "-u",
        "low",
        "-i",
        spec.icon,
        "-t",
        &spec.timeout_ms.to_string(),
        "-h",
        &format!("string:x-dunst-stack-tag:{}", spec.stack_tag),
    ]);

    if let Some(val) = spec.value {
        cmd.args(["-h", &format!("int:value:{val}")]);
    }

    if spec.body.is_empty() {
        cmd.arg(spec.title);
    } else {
        cmd.arg(spec.title).arg(spec.body);
    }

    cmd.stdin(std::process::Stdio::null())
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .spawn()
        .is_ok()
}

pub fn dispatch_rate_limited(spec: &NotificationSpec, runtime_dir: &Path, throttle_ms: u64) {
    let last_file = runtime_dir.join(format!("{}-last-notify", spec.stack_tag));
    let pending_file = runtime_dir.join(format!("{}-pending", spec.stack_tag));
    let trailing_pid_file = runtime_dir.join(format!("{}-trailing.pid", spec.stack_tag));

    let now_ms = get_now_ms();
    let last_ms = fs::read_to_string(&last_file)
        .ok()
        .and_then(|s| s.trim().parse::<u64>().ok())
        .unwrap_or(0);

    let diff = now_ms.saturating_sub(last_ms);

    if diff >= throttle_ms || last_ms > now_ms {
        let _ = fs::write(&last_file, now_ms.to_string());
        let _ = fs::remove_file(&pending_file);
        send_dunst_notification(spec);
    } else {
        // Save pending payload: title\tbody\tvalue\ticon
        let val_str = spec.value.map(|v| v.to_string()).unwrap_or_default();
        let payload = format!("{}\t{}\t{}\t{}", spec.title, spec.body, val_str, spec.icon);
        let _ = fs::write(&pending_file, payload);

        // Check if trailing daemon is already running
        let mut trailing_running = false;
        if let Ok(pid_str) = fs::read_to_string(&trailing_pid_file) {
            if let Ok(pid) = pid_str.trim().parse::<i32>() {
                if pid > 0 && unsafe { libc_kill_0(pid) } {
                    trailing_running = true;
                }
            }
        }

        if !trailing_running {
            if let Ok(exe) = std::env::current_exe() {
                if let Ok(child) = Command::new(exe)
                    .args([
                        "__trailing_flush",
                        spec.app_name,
                        &spec.id.to_string(),
                        spec.stack_tag,
                        &spec.timeout_ms.to_string(),
                    ])
                    .spawn()
                {
                    let _ = fs::write(&trailing_pid_file, child.id().to_string());
                }
            }
        }
    }
}

pub fn run_trailing_flush(
    app_name: &str,
    id: u32,
    stack_tag: &str,
    timeout_ms: u32,
    runtime_dir: &Path,
) {
    let pending_file = runtime_dir.join(format!("{stack_tag}-pending"));
    let last_file = runtime_dir.join(format!("{stack_tag}-last-notify"));
    let trailing_pid_file = runtime_dir.join(format!("{stack_tag}-trailing.pid"));

    std::thread::sleep(std::time::Duration::from_millis(80));

    if let Ok(content) = fs::read_to_string(&pending_file) {
        let _ = fs::remove_file(&pending_file);
        let parts: Vec<&str> = content.split('\t').collect();
        if parts.len() >= 4 {
            let title = parts[0];
            let body = parts[1];
            let val = parts[2].parse::<u32>().ok();
            let icon = parts[3];

            let spec = NotificationSpec {
                app_name,
                id,
                title,
                body,
                icon,
                value: val,
                stack_tag,
                timeout_ms,
            };
            let _ = fs::write(&last_file, get_now_ms().to_string());
            send_dunst_notification(&spec);
        }
    }

    let _ = fs::remove_file(&trailing_pid_file);
}

unsafe fn libc_kill_0(pid: i32) -> bool {
    extern "C" {
        fn kill(pid: std::os::raw::c_int, sig: std::os::raw::c_int) -> std::os::raw::c_int;
    }
    kill(pid, 0) == 0
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_now_ms() {
        let now = get_now_ms();
        assert!(now > 1_600_000_000_000);
    }
}
