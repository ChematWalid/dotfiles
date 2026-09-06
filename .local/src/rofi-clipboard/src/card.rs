//! High-performance card image renderer using ab_glyph and image.

use ab_glyph::{Font, FontArc, PxScaleFont, ScaleFont};
use image::imageops::FilterType;
use image::{Rgba, RgbaImage};
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::path::Path;
use std::process::Command;

use crate::theme::{ACCENT_COLOR, BG_COLOR, CARD_H, CARD_W, FG_COLOR, HEADER_BG, MUTED_COLOR};

pub struct Renderer {
    font_regular: FontArc,
    font_bold: FontArc,
}

impl Renderer {
    pub fn new() -> Self {
        let regular_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans.ttf"))
            .unwrap_or_default();
        let bold_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"))
            .unwrap_or_default();

        let font_regular = FontArc::try_from_vec(regular_bytes).unwrap_or_else(|_| {
            FontArc::try_from_slice(include_bytes!("/usr/share/fonts/TTF/DejaVuSans.ttf"))
                .expect("DejaVuSans font must exist")
        });
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

    fn draw_str(
        img: &mut RgbaImage,
        font: &FontArc,
        scale: f32,
        s: &str,
        start_x: f32,
        y: f32,
        color: Rgba<u8>,
    ) {
        let scaled_font = font.as_scaled(scale);
        let mut x = start_x;
        for c in s.chars() {
            Self::draw_char(img, &scaled_font, c, &mut x, y, color);
        }
    }

    fn wrap_text(&self, text: &str, scale: f32, max_w: f32) -> Vec<String> {
        let font = self.font_regular.as_scaled(scale);
        let mut lines = Vec::new();

        for block in text.lines() {
            if block.is_empty() {
                lines.push(String::new());
                continue;
            }
            let mut current = String::new();
            let mut current_w = 0.0;

            for word in block.split_inclusive(' ') {
                let word_w: f32 = word
                    .chars()
                    .map(|c| font.h_advance(font.scaled_glyph(c).id))
                    .sum();
                if current_w + word_w > max_w && !current.is_empty() {
                    lines.push(current);
                    current = word.to_string();
                    current_w = word_w;
                } else {
                    current.push_str(word);
                    current_w += word_w;
                }
            }
            if !current.is_empty() {
                lines.push(current);
            }
        }
        lines
    }

    pub fn render_text_card(&self, icon: &str, title: &str, sub: &str, text: &str) -> String {
        let mut hasher = DefaultHasher::new();
        icon.hash(&mut hasher);
        title.hash(&mut hasher);
        sub.hash(&mut hasher);
        text.hash(&mut hasher);
        let hash = hasher.finish();
        let path = format!("/tmp/copyq_thumbs/txt_{:x}.png", hash);

        if Path::new(&path).exists() {
            return path;
        }

        let mut img = RgbaImage::from_pixel(CARD_W, CARD_H, BG_COLOR);

        // Header Background
        for y in 0..64 {
            for x in 0..CARD_W {
                img.put_pixel(x, y, HEADER_BG);
            }
        }

        // Header Border Line
        for x in 0..CARD_W {
            img.put_pixel(x, 64, Rgba([49, 50, 68, 255]));
        }

        // Header Icon & Title
        let header_str = format!("{}  {}", icon, title);
        Self::draw_str(
            &mut img,
            &self.font_bold,
            22.0,
            &header_str,
            24.0,
            42.0,
            ACCENT_COLOR,
        );

        if !sub.is_empty() {
            Self::draw_str(
                &mut img,
                &self.font_regular,
                16.0,
                sub,
                24.0,
                96.0,
                MUTED_COLOR,
            );
        }

        // Body Text
        let y_start = if !sub.is_empty() { 128.0 } else { 96.0 };
        let lines = self.wrap_text(text, 18.0, 700.0);
        let line_height = 28.0;

        for (i, line) in lines.iter().enumerate() {
            let y = y_start + (i as f32) * line_height;
            if y > (CARD_H as f32 - 32.0) {
                Self::draw_str(
                    &mut img,
                    &self.font_regular,
                    18.0,
                    "… (truncated)",
                    24.0,
                    y,
                    MUTED_COLOR,
                );
                break;
            }
            Self::draw_str(&mut img, &self.font_regular, 18.0, line, 24.0, y, FG_COLOR);
        }

        let _ = img.save(&path);
        path
    }

    pub fn render_pdf_preview(&self, pdf_path: &Path) -> Option<String> {
        let prefix = format!("/tmp/copyq_thumbs/pdf_{:x}", {
            let mut h = DefaultHasher::new();
            pdf_path.hash(&mut h);
            h.finish()
        });
        let out_png = format!("{}-1.png", prefix);

        if Path::new(&out_png).exists() {
            return Some(out_png);
        }

        let status = Command::new("pdftoppm")
            .args([
                "-png",
                "-r",
                "100",
                "-f",
                "1",
                "-l",
                "1",
                pdf_path.to_str()?,
                &prefix,
            ])
            .status()
            .ok()?;

        if status.success() && Path::new(&out_png).exists() {
            Some(self.optimize_image(&out_png))
        } else {
            None
        }
    }

    pub fn optimize_image(&self, path: &str) -> String {
        let opt_path = format!("{}_opt.png", path);
        if Path::new(&opt_path).exists() {
            return opt_path;
        }

        if let Ok(img) = image::open(path) {
            let (w, h) = (img.width(), img.height());
            if w > 1400 || h > 1400 {
                let ratio = (1400.0 / w as f32).min(1400.0 / h as f32);
                let nw = (w as f32 * ratio) as u32;
                let nh = (h as f32 * ratio) as u32;
                let resized = img.resize_exact(nw, nh, FilterType::Triangle);
                let _ = resized.save(&opt_path);
                return opt_path;
            }
        }
        path.to_string()
    }
}
