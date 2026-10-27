mod config;
mod daemon;
mod engine;
mod scanner;

use std::env;
use std::io::{self, Write};
use std::process;

fn print_usage() {
    let stdout = io::stdout();
    let mut handle = stdout.lock();
    let lines = [
        "wallpaper-manager — Fast, native C++/Rust wallpaper manager and rotation daemon",
        "",
        "Usage:",
        "  wallpaper-manager daemon          Run the 30-minute rotation daemon",
        "  wallpaper-manager next            Pick a new random wallpaper and reset rotation timer",
        "  wallpaper-manager prev            Return to the previously displayed wallpaper",
        "  wallpaper-manager set <PATH>      Set a specific image as wallpaper",
        "  wallpaper-manager list            List all wallpapers in current collection",
        "  wallpaper-manager current         Show current wallpaper path",
        "  wallpaper-manager dir [PATH]      View or change wallpaper directory",
        "  wallpaper-manager dir reset       Reset to default Catppuccin Mocha collection",
        "  wallpaper-manager -h, --help      Show this help message",
    ];
    for line in lines {
        if let Err(e) = writeln!(handle, "{line}") {
            if e.kind() == io::ErrorKind::BrokenPipe {
                return;
            }
        }
    }
}

fn handle_dir(args: &[String]) {
    let stdout = io::stdout();
    let mut handle = stdout.lock();

    if args.is_empty() {
        let current_dir = config::get_configured_wallpaper_dir();
        let walls = scanner::scan_wallpapers(&current_dir, 3);
        let current_dir_line = format!("   {}", current_dir.display());
        let count_line = format!(
            "   Found {} wallpapers (searching 3 folders deep)",
            walls.len()
        );
        let lines: [&str; 7] = [
            "🌄 Current wallpaper directory:",
            &current_dir_line,
            &count_line,
            "",
            "Usage:",
            "   wallpaper-manager dir <path/to/folder>   — Switch to a new wallpaper folder",
            "   wallpaper-manager dir reset              — Reset to default Catppuccin collection",
        ];
        for line in lines {
            if let Err(e) = writeln!(handle, "{line}") {
                if e.kind() == io::ErrorKind::BrokenPipe {
                    return;
                }
            }
        }
        return;
    }

    let target_arg = &args[0];
    let target = if target_arg == "reset" || target_arg == "--reset" {
        config::default_wallpaper_dir()
    } else {
        config::expand_path(target_arg)
    };

    if !target.is_dir() {
        eprintln!("❌ Error: Directory '{}' does not exist.", target.display());
        process::exit(1);
    }
    let target = target.canonicalize().unwrap_or(target);

    let walls = scanner::scan_wallpapers(&target, 3);
    if walls.is_empty() {
        eprintln!(
            "⚠️  Warning: No images (.jpg, .png, .jpeg, .webp) found in '{}' (searched 3 folders deep).",
            target.display()
        );
        eprintln!("Directory was not changed.");
        process::exit(1);
    }

    if let Err(e) = config::set_configured_wallpaper_dir(&target) {
        eprintln!("❌ Error saving configuration: {}", e);
        process::exit(1);
    }

    let _ = writeln!(handle, "✅ Wallpaper directory updated to: {}", target.display());
    let _ = writeln!(handle, "   Found {} wallpapers.", walls.len());
    let _ = writeln!(handle, "   Switching wallpaper now...");

    if let Err(e) = engine::switch_next(true) {
        eprintln!("❌ Error switching wallpaper: {}", e);
        process::exit(1);
    }
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    if args.is_empty() {
        print_usage();
        return;
    }

    match args[0].as_str() {
        "daemon" => {
            if let Err(e) = daemon::run_daemon() {
                eprintln!("wallpaper-manager daemon error: {}", e);
                process::exit(1);
            }
        }
        "next" => match engine::switch_next(true) {
            Ok(path) => {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "Switched to: {}", path.display());
            }
            Err(e) => {
                eprintln!("Error: {}", e);
                process::exit(1);
            }
        },
        "prev" | "previous" => match engine::switch_prev(true) {
            Ok(path) => {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "Switched to previous: {}", path.display());
            }
            Err(e) => {
                eprintln!("Error: {}", e);
                process::exit(1);
            }
        },
        "set" => {
            if args.len() < 2 {
                eprintln!("Usage: wallpaper-manager set <PATH>");
                process::exit(2);
            }
            let target = config::expand_path(&args[1]);
            match engine::set_specific_wallpaper(&target, true) {
                Ok(()) => {
                    let stdout = io::stdout();
                    let mut handle = stdout.lock();
                    let _ = writeln!(handle, "✅ Wallpaper set to: {}", target.display());
                }
                Err(e) => {
                    eprintln!("Error: {}", e);
                    process::exit(1);
                }
            }
        }
        "list" => {
            let walls = engine::list_wallpapers();
            let current = config::get_current_wallpaper();
            let wall_dir = config::get_configured_wallpaper_dir();
            let stdout = io::stdout();
            let mut handle = stdout.lock();
            if let Err(e) = writeln!(handle, "📁 Wallpapers in {} ({} total):", wall_dir.display(), walls.len()) {
                if e.kind() == io::ErrorKind::BrokenPipe {
                    return;
                }
            }
            for (i, w) in walls.iter().enumerate() {
                let mark = if current.as_ref() == Some(w) { " [*active*]" } else { "" };
                if let Err(e) = writeln!(handle, "  {:2}. {}{}", i + 1, w.display(), mark) {
                    if e.kind() == io::ErrorKind::BrokenPipe {
                        break;
                    }
                }
            }
        }
        "current" => match config::get_current_wallpaper() {
            Some(path) => {
                let stdout = io::stdout();
                let mut handle = stdout.lock();
                let _ = writeln!(handle, "{}", path.display());
            }
            None => {
                eprintln!("No wallpaper currently set.");
                process::exit(1);
            }
        },
        "dir" => {
            handle_dir(&args[1..]);
        }
        "-h" | "--help" | "help" => {
            print_usage();
        }
        other => {
            eprintln!("Unknown command: '{other}'");
            let stdout = io::stdout();
            let mut handle = stdout.lock();
            let _ = writeln!(handle);
            drop(handle);
            print_usage();
            process::exit(1);
        }
    }
}
