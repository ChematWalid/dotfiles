mod brightness;
mod lock;
mod osd;
mod sink;
mod volume;

use std::env;
use std::io::{self, Write};
use std::process;

use brightness::{execute_brightness_action, BrightnessAction};
use lock::get_runtime_dir;
use sink::toggle_audio_sink;
use volume::{execute_volume_action, VolumeAction};

fn print_usage() {
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    let lines = [
        "desktop-osd — High-performance, modular native Rust OSD and media controller",
        "",
        "Usage:",
        "  desktop-osd volume {up|down|mute|mic-mute|get} [step]   Adjust or query volume",
        "  desktop-osd brightness {up|down|get} [step]           Adjust or query brightness",
        "  desktop-osd sink {toggle|next|status}                  Switch or inspect audio output sink",
        "  desktop-osd status                                    Overview of volume, brightness & sink",
        "  desktop-osd -h, --help                                Show this help message",
        "  desktop-osd -v, --version                             Show version",
    ];
    for line in lines {
        if let Err(e) = writeln!(handle, "{line}") {
            if e.kind() == io::ErrorKind::BrokenPipe {
                return;
            }
        }
    }
}

fn handle_volume(args: &[String]) {
    let action_str = args.first().map(|s| s.as_str()).unwrap_or("get");
    let step = args.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(1);

    let action = match action_str {
        "up" | "increase" => VolumeAction::Up(step),
        "down" | "decrease" => VolumeAction::Down(step),
        "mute" | "toggle-mute" => VolumeAction::Mute,
        "mic-mute" | "mic" => VolumeAction::MicMute,
        "get" | "status" | "" => VolumeAction::Get,
        other => {
            eprintln!("Unknown volume action: '{other}'");
            eprintln!("Usage: desktop-osd volume {{up|down|mute|mic-mute|get}} [step]");
            process::exit(2);
        }
    };

    let runtime_dir = get_runtime_dir();
    match execute_volume_action(&action, &runtime_dir) {
        Ok(state) => {
            if action == VolumeAction::Get {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "{}", state.raw_text);
            }
        }
        Err(err) => {
            eprintln!("Volume error: {err}");
            process::exit(1);
        }
    }
}

fn handle_brightness(args: &[String]) {
    let action_str = args.first().map(|s| s.as_str()).unwrap_or("get");
    let step = args.get(1).and_then(|s| s.parse::<u32>().ok()).unwrap_or(10);

    let action = match action_str {
        "up" | "increase" => BrightnessAction::Up(step),
        "down" | "decrease" => BrightnessAction::Down(step),
        "get" | "status" | "" => BrightnessAction::Get,
        other => {
            eprintln!("Unknown brightness action: '{other}'");
            eprintln!("Usage: desktop-osd brightness {{up|down|get}} [step]");
            process::exit(2);
        }
    };

    let runtime_dir = get_runtime_dir();
    match execute_brightness_action(&action, &runtime_dir) {
        Ok(val) => {
            if action == BrightnessAction::Get {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "{val}%");
            }
        }
        Err(err) => {
            eprintln!("Brightness error: {err}");
            process::exit(1);
        }
    }
}

fn handle_sink(args: &[String]) {
    let action_str = args.first().map(|s| s.as_str()).unwrap_or("toggle");

    let runtime_dir = get_runtime_dir();
    match action_str {
        "toggle" | "next" | "" => match toggle_audio_sink(&runtime_dir) {
            Ok(info) => {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "Switched to: {} [{}] ({})", info.description, info.icon, info.name);
            }
            Err(err) => {
                eprintln!("Sink toggle error: {err}");
                process::exit(1);
            }
        },
        "status" | "get" => {
            let sinks = sink::get_sinks();
            let def_name = sink::get_default_sink_name();
            let stdout = io::stdout();
            let mut handle = stdout.lock();
            if let Some(ref def) = def_name {
                let desc = sinks
                    .iter()
                    .find(|s| &s.name == def)
                    .and_then(|s| s.description.clone())
                    .unwrap_or_else(|| def.clone());
                if let Err(e) = writeln!(handle, "Default Sink: {desc} ({def})") {
                    if e.kind() == io::ErrorKind::BrokenPipe {
                        return;
                    }
                }
            }
            if let Err(e) = writeln!(handle, "Available Sinks ({}):", sinks.len()) {
                if e.kind() == io::ErrorKind::BrokenPipe {
                    return;
                }
            }
            for s in &sinks {
                let desc = s.description.as_deref().unwrap_or(&s.name);
                let mark = if def_name.as_ref() == Some(&s.name) { " [*active*]" } else { "" };
                if let Err(e) = writeln!(handle, "  - {desc} [{}]{mark}", s.name) {
                    if e.kind() == io::ErrorKind::BrokenPipe {
                        return;
                    }
                }
                if !s.ports.is_empty() {
                    for p in &s.ports {
                        let pdesc = p.description.as_deref().unwrap_or(&p.name);
                        let port_mark = if s.active_port.as_deref() == Some(&p.name) { " (active)" } else { "" };
                        let avail = p.availability.as_deref().map(|a| format!(" ({a})")).unwrap_or_default();
                        if let Err(e) = writeln!(handle, "      • {pdesc} [{port_name}]{avail}{port_mark}", port_name = p.name) {
                            if e.kind() == io::ErrorKind::BrokenPipe {
                                return;
                            }
                        }
                    }
                }
            }
        }
        other => {
            eprintln!("Unknown sink action: '{other}'");
            eprintln!("Usage: desktop-osd sink {{toggle|status}}");
            process::exit(2);
        }
    }
}

fn handle_status() {
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    if let Err(e) = writeln!(handle, "=== Desktop Status Overview ===") {
        if e.kind() == io::ErrorKind::BrokenPipe {
            return;
        }
    }
    let runtime_dir = get_runtime_dir();

    if let Ok(vol) = execute_volume_action(&VolumeAction::Get, &runtime_dir) {
        if let Err(e) = writeln!(handle, "🔊 Volume:     {}", vol.raw_text) {
            if e.kind() == io::ErrorKind::BrokenPipe {
                return;
            }
        }
    }
    if let Ok(bright) = execute_brightness_action(&BrightnessAction::Get, &runtime_dir) {
        if let Err(e) = writeln!(handle, "󰃠  Brightness: {}%", bright) {
            if e.kind() == io::ErrorKind::BrokenPipe {
                return;
            }
        }
    }
    let sinks = sink::get_sinks();
    if let Some(def) = sink::get_default_sink_name() {
        if let Some(s) = sinks.iter().find(|s| s.name == def) {
            let desc = s.description.as_deref().unwrap_or(&s.name);
            let port_str = s.active_port.as_deref()
                .and_then(|ap| s.ports.iter().find(|p| p.name == ap))
                .and_then(|p| p.description.as_deref())
                .map(|pd| format!(" ({pd})"))
                .unwrap_or_default();
            let _ = writeln!(handle, "🎧 Audio Sink: {desc}{port_str}");
        } else {
            let _ = writeln!(handle, "🎧 Audio Sink: {def}");
        }
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let program_name = args.first().map(|s| s.as_str()).unwrap_or("desktop-osd");

    // Check shorthand symlink execution
    if program_name.ends_with("volume-osd") || program_name.ends_with("volume-osd.sh") {
        handle_volume(&args[1..]);
        return;
    }
    if program_name.ends_with("brightness-osd") || program_name.ends_with("brightness-osd.sh") {
        handle_brightness(&args[1..]);
        return;
    }
    if program_name.ends_with("toggle-audio-sink") || program_name.ends_with("toggle-audio-sink.sh") {
        handle_sink(&args[1..]);
        return;
    }

    if args.len() < 2 {
        print_usage();
        return;
    }

    match args[1].as_str() {
        "volume" | "vol" => handle_volume(&args[2..]),
        "brightness" | "bright" => handle_brightness(&args[2..]),
        "sink" | "audio-sink" => handle_sink(&args[2..]),
        "status" => handle_status(),
        "__trailing_flush" => {
            if args.len() >= 6 {
                let app_name = &args[2];
                let id = args[3].parse::<u32>().unwrap_or(0);
                let stack_tag = &args[4];
                let timeout_ms = args[5].parse::<u32>().unwrap_or(1200);
                let runtime_dir = get_runtime_dir();
                osd::run_trailing_flush(app_name, id, stack_tag, timeout_ms, &runtime_dir);
            }
        }
        "-h" | "--help" => print_usage(),
        "-v" | "--version" => {
            let stdout = io::stdout();
            let mut handle = stdout.lock();
            let _ = writeln!(handle, "desktop-osd {}", env!("CARGO_PKG_VERSION"));
        }
        other => {
            eprintln!("Unknown command: '{other}'");
            print_usage();
            process::exit(2);
        }
    }
}
