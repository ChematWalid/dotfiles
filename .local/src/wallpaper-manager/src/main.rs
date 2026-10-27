mod config;
mod daemon;
mod engine;
mod scanner;

use std::env;
use std::process;

fn print_usage() {
    println!("wallpaper-manager — Fast, native C++/Rust wallpaper manager and rotation daemon");
    println!();
    println!("Usage:");
    println!("  wallpaper-manager daemon          Run the 30-minute rotation daemon");
    println!("  wallpaper-manager next            Pick a new random wallpaper and reset rotation timer");
    println!("  wallpaper-manager current         Show current wallpaper path");
    println!("  wallpaper-manager dir [PATH]      View or change wallpaper directory");
    println!("  wallpaper-manager dir reset       Reset to default Catppuccin Mocha collection");
    println!("  wallpaper-manager -h, --help      Show this help message");
}

fn handle_dir(args: &[String]) {
    if args.is_empty() {
        let current_dir = config::get_configured_wallpaper_dir();
        let walls = scanner::scan_wallpapers(&current_dir, 3);
        println!("🌄 Current wallpaper directory:");
        println!("   {}", current_dir.display());
        println!(
            "   Found {} wallpapers (searching 3 folders deep)",
            walls.len()
        );
        println!();
        println!("Usage:");
        println!("   wallpaper-manager dir <path/to/folder>   — Switch to a new wallpaper folder");
        println!("   wallpaper-manager dir reset              — Reset to default Catppuccin collection");
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

    println!("✅ Wallpaper directory updated to: {}", target.display());
    println!("   Found {} wallpapers.", walls.len());
    println!("   Switching wallpaper now...");

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
                println!("Switched to: {}", path.display());
            }
            Err(e) => {
                eprintln!("Error: {}", e);
                process::exit(1);
            }
        },
        "current" => match config::get_current_wallpaper() {
            Some(path) => println!("{}", path.display()),
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
            eprintln!("Unknown command: '{}'", other);
            println!();
            print_usage();
            process::exit(1);
        }
    }
}
