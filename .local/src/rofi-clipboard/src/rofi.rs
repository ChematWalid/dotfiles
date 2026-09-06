//! Rofi UI construction and runner.

use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::card::Renderer;
use crate::copyq::CopyQItem;
use crate::theme::CACHE_DIR;

fn dirs_home() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/home/walid"))
}

pub fn run_rofi(items: &[CopyQItem], renderer: &Renderer) -> Option<usize> {
    let mut rofi_entries = Vec::new();

    for item in items {
        let (preview, label) = if item.is_image {
            let raw_path = format!("{}/{}", CACHE_DIR, item.raw_img);
            if Path::new(&raw_path).exists() {
                let opt = renderer.optimize_image(&raw_path);
                (opt, format!("  [Image #{}]", item.i))
            } else {
                let card = renderer.render_text_card(
                    "",
                    "Image Thumbnail",
                    "",
                    "Image format unavailable",
                );
                (card, format!("  [Image #{}]", item.i))
            }
        } else if item.is_files {
            let paths: Vec<&str> = item
                .text
                .lines()
                .map(|l| l.trim().strip_prefix("file://").unwrap_or(l.trim()))
                .filter(|p| !p.is_empty())
                .collect();

            let count = paths.len();
            let label = if count == 1 {
                let fname = Path::new(paths[0])
                    .file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or(paths[0]);
                format!("  File: {}", fname)
            } else {
                format!("  {} files attached", count)
            };

            let preview = if count == 1 && paths[0].to_lowercase().ends_with(".pdf") {
                renderer
                    .render_pdf_preview(Path::new(paths[0]))
                    .unwrap_or_else(|| {
                        renderer.render_text_card(
                            "",
                            "PDF Document",
                            paths[0],
                            "PDF preview rendering failed",
                        )
                    })
            } else {
                renderer.render_text_card(
                    "",
                    "File List",
                    &format!("{} files attached", count),
                    &paths.join("\n"),
                )
            };
            (preview, label)
        } else {
            let text = &item.text;
            let clean_label = text.lines().next().unwrap_or("Empty item").trim();
            let clean_label = if clean_label.chars().count() > 36 {
                let sub: String = clean_label.chars().take(33).collect();
                format!("{}...", sub)
            } else {
                clean_label.to_string()
            };

            let char_count = text.chars().count();
            let line_count = text.lines().count();
            let sub = if line_count > 1 || char_count > 40 {
                format!("({} lines • {} chars)", line_count, char_count)
            } else {
                String::new()
            };
            let card = renderer.render_text_card("", "Text Preview", &sub, text);
            (card, format!("  {}", clean_label))
        };

        rofi_entries.push(format!("{}\0icon\x1f{}", label, preview));
    }

    let rofi_input = rofi_entries.join("\n");

    let theme_overrides = "configuration { show-icons: false; } \
         window { width: 1060px; height: 580px; border: 0px; border-radius: 12px; } \
         mainbox { children: [ inputbar, bodybox ]; background-color: @bg-col; border: 0px; } \
         bodybox { orientation: horizontal; children: [ listview, previewbox ]; background-color: transparent; spacing: 16px; margin: 8px 16px 16px 16px; border: 0px; } \
         listview { columns: 1; lines: 9; width: 440px; margin: 0px; padding: 0px; background-color: transparent; border: 0px; scrollbar: false; } \
         previewbox { orientation: vertical; children: [ icon-current-entry ]; background-color: #181825; border: 0px; border-radius: 10px; padding: 8px; width: 560px; } \
         icon-current-entry { size: 520px; horizontal-align: 0.5; vertical-align: 0.5; background-color: transparent; border-radius: 8px; } \
         element { padding: 8px 12px; border-radius: 6px; children: [ element-text ]; } \
         element-icon { enabled: false; size: 0px; max-width: 0px; max-height: 0px; margin: 0px; padding: 0px; border: 0px; } \
         element-text { vertical-align: 0.5; font: \"JetBrainsMono Nerd Font 11\"; }";

    let config_rasi = dirs_home().join(".config/rofi/config.rasi");

    let mut rofi_cmd = Command::new("rofi")
        .args([
            "-dmenu",
            "-i",
            "-p",
            "󰅌 Clipboard",
            "-format",
            "i",
            "-theme",
            config_rasi.to_str().unwrap_or(""),
            "-theme-str",
            theme_overrides,
        ])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .ok()?;

    if let Some(mut stdin) = rofi_cmd.stdin.take() {
        let _ = stdin.write_all(rofi_input.as_bytes());
    }

    let output = rofi_cmd.wait_with_output().ok()?;
    let selected = String::from_utf8_lossy(&output.stdout).trim().to_string();

    selected.parse::<usize>().ok()
}
