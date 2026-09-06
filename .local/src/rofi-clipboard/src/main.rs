//! rofi-clipboard — High-performance Rofi Clipboard Picker with Large Previews powered by CopyQ.
//! Converted from Python (PIL) to Rust for instantaneous sub-20ms startup.

use ab_glyph::{Font, FontArc, PxScaleFont, ScaleFont};
use image::imageops::FilterType;
use image::{Rgba, RgbaImage};
use serde::Deserialize;
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

const CACHE_DIR: &str = "/tmp/copyq_thumbs";
const MAX_ITEMS: usize = 35;
const CARD_W: u32 = 750;
const CARD_H: u32 = 560;

const BG_COLOR: Rgba<u8> = Rgba([24, 24, 37, 255]);       // Catppuccin Mantle
const HEADER_BG: Rgba<u8> = Rgba([30, 30, 46, 255]);     // Catppuccin Base
const ACCENT_COLOR: Rgba<u8> = Rgba([203, 166, 247, 255]); // Catppuccin Mauve
const FG_COLOR: Rgba<u8> = Rgba([205, 214, 244, 255]);     // Catppuccin Text
const MUTED_COLOR: Rgba<u8> = Rgba([108, 112, 134, 255]);  // Catppuccin Overlay0

#[derive(Debug, Deserialize)]
struct CopyQItem {
    i: usize,
    #[serde(rename = "isImage")]
    is_image: bool,
    #[serde(rename = "isFiles")]
    is_files: bool,
    text: String,
    #[serde(rename = "rawImg")]
    raw_img: String,
}

struct Renderer {
    font_regular: FontArc,
    font_bold: FontArc,
}

impl Renderer {
    fn new() -> Self {
        let regular_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans.ttf"))
            .unwrap_or_default();
        let bold_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"))
            .unwrap_or_default();

        let font_regular = FontArc::try_from_vec(regular_bytes)
            .unwrap_or_else(|_| FontArc::try_from_slice(include_bytes!("/usr/share/fonts/TTF/DejaVuSans.ttf")).unwrap());
        let font_bold = FontArc::try_from_vec(bold_bytes).unwrap_or_else(|_| font_regular.clone());

        Renderer {
            font_regular,
            font_bold,
        }
    }

    fn draw_char(
        img: &mut RgbaImage,
        font: &PxScaleFont<&FontArc>,
        c: char,
        x: &mut f32,
        y: f32,
        color: Rgba<u8>,
    ) {
        let glyph = font.scaled_glyph(c);
        let h_advance = font.h_advance(glyph.id);
        let mut g = glyph;
        g.position.x = *x;
        g.position.y = y;

        if let Some(outlined) = font.outline_glyph(g) {
            let bounds = outlined.px_bounds();
            outlined.draw(|gx, gy, c_val| {
                let px = bounds.min.x as i32 + gx as i32;
                let py = bounds.min.y as i32 + gy as i32;
                if px >= 0 && (px as u32) < img.width() && py >= 0 && (py as u32) < img.height() {
                    let px = px as u32;
                    let py = py as u32;
                    let alpha = (c_val * 255.0) as u8;
                    if alpha > 0 {
                        let mut p = *img.get_pixel(px, py);
                        let a = alpha as f32 / 255.0;
                        p[0] = ((1.0 - a) * p[0] as f32 + a * color[0] as f32) as u8;
                        p[1] = ((1.0 - a) * p[1] as f32 + a * color[1] as f32) as u8;
                        p[2] = ((1.0 - a) * p[2] as f32 + a * color[2] as f32) as u8;
                        p[3] = 255;
                        img.put_pixel(px, py, p);
                    }
                }
            });
        }
        *x += h_advance;
    }

    fn draw_text(
        &self,
        img: &mut RgbaImage,
        text: &str,
        start_x: f32,
        y: f32,
        scale: f32,
        bold: bool,
        color: Rgba<u8>,
    ) {
        let font_ref = if bold { &self.font_bold } else { &self.font_regular };
        let scaled = font_ref.as_scaled(scale);
        let mut x = start_x;
        for c in text.chars() {
            if c == '\t' {
                x += scaled.h_advance(scaled.scaled_glyph(' ').id) * 4.0;
            } else {
                Self::draw_char(img, &scaled, c, &mut x, y, color);
            }
        }
    }

    fn render_text_card(&self, icon: &str, title: &str, subtitle: &str, body: &str) -> String {
        let mut hasher = DefaultHasher::new();
        icon.hash(&mut hasher);
        title.hash(&mut hasher);
        subtitle.hash(&mut hasher);
        body.hash(&mut hasher);
        let hash = format!("{:016x}", hasher.finish());

        let out_path = format!("{}/card_{}.png", CACHE_DIR, hash);
        if Path::new(&out_path).exists() {
            return out_path;
        }

        let mut img = RgbaImage::from_pixel(CARD_W, CARD_H, BG_COLOR);

        // Header bar
        for y in 0..42 {
            for x in 0..CARD_W {
                img.put_pixel(x, y, HEADER_BG);
            }
        }

        // Header icon and title
        let mut h_text = format!("{}  {}", icon, title);
        if !subtitle.is_empty() {
            h_text.push_str(&format!("   {}", subtitle));
        }
        self.draw_text(&mut img, &h_text, 16.0, 26.0, 15.0, true, ACCENT_COLOR);

        // Body lines
        let line_height = 21.0;
        let mut y = 62.0;
        let max_lines = 22;
        let lines: Vec<&str> = body.lines().collect();

        for (idx, line) in lines.iter().take(max_lines).enumerate() {
            // Line number gutter
            let line_num = format!("{:2}", idx + 1);
            self.draw_text(&mut img, &line_num, 16.0, y, 12.0, false, MUTED_COLOR);

            // Line content (truncate to avoid wrapping off-screen)
            let display_line: String = line.chars().take(72).collect();
            self.draw_text(&mut img, &display_line, 48.0, y, 14.0, false, FG_COLOR);
            y += line_height;
        }

        if lines.len() > max_lines {
            let more = format!("... and {} more lines", lines.len() - max_lines);
            self.draw_text(&mut img, &more, 48.0, y, 12.0, false, MUTED_COLOR);
        }

        let _ = img.save(&out_path);
        out_path
    }

    fn optimize_image(&self, img_path: &str) -> String {
        if !Path::new(img_path).exists() {
            return String::new();
        }

        let mut hasher = DefaultHasher::new();
        img_path.hash(&mut hasher);
        if let Ok(meta) = fs::metadata(img_path) {
            meta.len().hash(&mut hasher);
        }
        let hash = format!("{:016x}", hasher.finish());

        let out_path = format!("{}/opt_{}.png", CACHE_DIR, hash);
        if Path::new(&out_path).exists() {
            return out_path;
        }

        if let Ok(img) = image::open(img_path) {
            let (w, h) = (img.width(), img.height());
            if w > 1400 || h > 1400 {
                let ratio = 1400.0 / w.max(h) as f32;
                let nw = (w as f32 * ratio) as u32;
                let nh = (h as f32 * ratio) as u32;
                let resized = image::imageops::resize(&img, nw, nh, FilterType::Triangle);
                let _ = resized.save(&out_path);
                return out_path;
            } else {
                let _ = img.save(&out_path);
                return out_path;
            }
        }

        img_path.to_string()
    }
}

fn render_pdf_preview(pdf_path: &str) -> Option<String> {
    if !Path::new(pdf_path).exists() {
        return None;
    }
    let mut hasher = DefaultHasher::new();
    pdf_path.hash(&mut hasher);
    let hash = format!("{:016x}", hasher.finish());

    let out_path = format!("{}/pdf_{}.png", CACHE_DIR, hash);
    if Path::new(&out_path).exists() {
        return Some(out_path);
    }

    let prefix = format!("{}/tmp_pdf_{}", CACHE_DIR, hash);
    let status = Command::new("pdftoppm")
        .args(["-png", "-f", "1", "-l", "1", "-scale-to", "900", pdf_path, &prefix])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .ok()?;

    if status.success() {
        let cand1 = format!("{}-1.png", prefix);
        let cand2 = format!("{}-01.png", prefix);
        let src = if Path::new(&cand1).exists() {
            cand1
        } else if Path::new(&cand2).exists() {
            cand2
        } else {
            return None;
        };
        let _ = fs::rename(&src, &out_path);
        return Some(out_path);
    }
    None
}

fn fetch_copyq_items() -> Vec<CopyQItem> {
    let _ = fs::create_dir_all(CACHE_DIR);

    let js_code = format!(
        r#"
        var NL = String.fromCharCode(10);
        var res = [];
        var n = Math.min(size(), {});
        for (var i = 0; i < n; ++i) {{
            var formats = str(read("?", i));
            var isImage = formats.indexOf("image/png") !== -1 || formats.indexOf("image/jpeg") !== -1;
            var isFiles = formats.indexOf("text/uri-list") !== -1;
            var rawText = isImage ? "" : str(read(i));
            var rawImg = "";
            if (isImage) {{
                var b = read("image/png", i);
                if (b.size() === 0) b = read("image/jpeg", i);
                var sz = b.size();
                rawImg = "raw_" + i + "_" + sz + ".png";
                var f = new File('{}/' + rawImg);
                if (!f.exists() && f.open(File.WriteOnly)) {{
                    f.write(b);
                    f.close();
                }}
            }}
            res.push({{
                i: i,
                isImage: isImage,
                isFiles: isFiles,
                text: rawText,
                rawImg: rawImg
            }});
        }}
        JSON.stringify(res);
        "#,
        MAX_ITEMS, CACHE_DIR
    );

    let out = Command::new("copyq")
        .args(["eval", &js_code])
        .stderr(Stdio::null())
        .output()
        .map(|o| o.stdout)
        .unwrap_or_default();

    serde_json::from_slice(&out).unwrap_or_default()
}

fn handle_single_file(fpath: &str, renderer: &Renderer) -> (String, String) {
    let path = Path::new(fpath);
    let fname = path.file_name().and_then(|f| f.to_str()).unwrap_or("file");
    let ext = path.extension().and_then(|e| e.to_str()).unwrap_or("").to_lowercase();
    let size_str = if let Ok(m) = fs::metadata(fpath) {
        format!("{:.1} KB", m.len() as f64 / 1024.0)
    } else {
        String::new()
    };

    // 1. Image files
    match ext.as_str() {
        "png" | "jpg" | "jpeg" | "webp" | "svg" | "bmp" | "gif" | "ico" => {
            let opt = renderer.optimize_image(fpath);
            return (opt, format!("  {}", fname));
        }
        "pdf" => {
            if let Some(pdf_img) = render_pdf_preview(fpath) {
                return (pdf_img, format!("  {}", fname));
            }
            let card = renderer.render_text_card(
                "",
                fname,
                "(PDF Document)",
                &format!("PDF Document\nPath: {}\nSize: {}", fpath, size_str),
            );
            return (card, format!("  {}", fname));
        }
        "zip" | "tar" | "gz" | "tgz" | "xz" => {
            let manifest = if ext == "zip" {
                Command::new("unzip")
                    .args(["-l", fpath])
                    .output()
                    .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
                    .unwrap_or_default()
            } else {
                Command::new("tar")
                    .args(["-tf", fpath])
                    .output()
                    .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
                    .unwrap_or_default()
            };
            let card = renderer.render_text_card(
                "",
                fname,
                &format!("({} • Archive)", size_str),
                &manifest,
            );
            return (card, format!("  {}", fname));
        }
        _ => {}
    }

    // Text / Source code / Config file
    if let Ok(content) = fs::read_to_string(fpath) {
        let line_count = content.lines().count();
        let card = renderer.render_text_card(
            "",
            fname,
            &format!("({} • {} lines)", size_str, line_count),
            &content,
        );
        return (card, format!("  {}", fname));
    }

    // Binary fallback
    let card = renderer.render_text_card(
        "📦",
        fname,
        &format!("({})", size_str),
        &format!("File: {}\nPath: {}\nSize: {}\nBinary / System file", fname, fpath, size_str),
    );
    (card, format!("📦  {}", fname))
}

fn main() {
    let items = fetch_copyq_items();
    if items.is_empty() {
        let config_rasi = dirs_home().join(".config/rofi/config.rasi");
        let _ = Command::new("rofi")
            .args([
                "-e",
                "Clipboard is empty or CopyQ daemon is not running.",
                "-theme",
                config_rasi.to_str().unwrap_or(""),
            ])
            .status();
        return;
    }

    let renderer = Renderer::new();
    let mut rofi_entries = Vec::new();

    for it in &items {
        let (preview, label) = if it.is_image {
            let full_raw = format!("{}/{}", CACHE_DIR, it.raw_img);
            let opt = renderer.optimize_image(&full_raw);
            (opt, "  Image / Screenshot".to_string())
        } else if it.is_files {
            let files: Vec<&str> = it
                .text
                .lines()
                .filter_map(|line| {
                    let trimmed = line.trim();
                    if trimmed.starts_with("file://") {
                        Some(&trimmed[7..])
                    } else if !trimmed.is_empty() {
                        Some(trimmed)
                    } else {
                        None
                    }
                })
                .collect();

            if files.len() == 1 && Path::new(files[0]).exists() {
                handle_single_file(files[0], &renderer)
            } else if files.len() > 1 {
                let names: Vec<&str> = files
                    .iter()
                    .filter_map(|f| Path::new(f).file_name().and_then(|n| n.to_str()))
                    .collect();
                let summary = format!("{} files:\n\n{}", files.len(), files.join("\n"));
                let card = renderer.render_text_card("", &format!("{} Files Copied", files.len()), "", &summary);
                let label = format!("  {}", names.iter().take(3).cloned().collect::<Vec<_>>().join(", "));
                (card, label)
            } else {
                let card = renderer.render_text_card("", "Files", "", "No valid file paths");
                (card, "  Files".to_string())
            }
        } else {
            let text = it.text.trim();
            if Path::new(text).exists() && Path::new(text).is_file() {
                handle_single_file(text, &renderer)
            } else if text.starts_with("http://") || text.starts_with("https://") {
                let clean_url = text.replace('\n', "");
                let label = format!("  {}", clean_url.chars().take(55).collect::<String>());
                let card = renderer.render_text_card("", "Link Preview", "", &format!("URL:\n{}\n", clean_url));
                (card, label)
            } else {
                let first_line = text.lines().next().unwrap_or("").trim();
                let clean_label = if first_line.len() > 50 {
                    format!("{}...", &first_line[..47])
                } else if first_line.is_empty() {
                    "[Empty]".to_string()
                } else {
                    first_line.to_string()
                };
                let line_count = text.lines().count();
                let char_count = text.chars().count();
                let sub = if line_count > 1 || char_count > 50 {
                    format!("({} lines • {} chars)", line_count, char_count)
                } else {
                    String::new()
                };
                let card = renderer.render_text_card("", "Text Preview", &sub, text);
                (card, format!("  {}", clean_label))
            }
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
        .expect("Failed to start rofi");

    if let Some(mut stdin) = rofi_cmd.stdin.take() {
        let _ = stdin.write_all(rofi_input.as_bytes());
    }

    let output = rofi_cmd.wait_with_output().expect("Failed to wait on rofi");
    let selected = String::from_utf8_lossy(&output.stdout).trim().to_string();

    if let Ok(idx) = selected.parse::<usize>() {
        if idx < items.len() {
            let item_idx = items[idx].i;
            let _ = Command::new("copyq")
                .args(["select", &item_idx.to_string()])
                .status();
            thread::sleep(Duration::from_millis(80));
            let _ = Command::new("copyq").arg("paste").status();
        }
    }
}

fn dirs_home() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/home/walid"))
}
