//! High-performance card image renderer using swash and image.

use image::imageops::FilterType;
use image::{Rgba, RgbaImage};
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::path::{Path, PathBuf};
use std::process::Command;
use swash::scale::{image::Image, Render, ScaleContext, Scaler, Source};
use swash::zeno::Format;
use swash::FontRef;

use crate::theme::{ACCENT_COLOR, BG_COLOR, CARD_H, CARD_W, FG_COLOR, HEADER_BG, MUTED_COLOR};

fn valid_font(data: Vec<u8>) -> Option<Vec<u8>> {
    let valid = FontRef::from_index(&data, 0).is_some();
    valid.then_some(data)
}

pub struct Renderer {
    font_regular: Vec<u8>,
    font_bold: Vec<u8>,
    cache_dir: PathBuf,
}

#[derive(Clone, Copy)]
struct TextStyle {
    scale: f32,
    position: (f32, f32),
    color: Rgba<u8>,
}

impl Renderer {
    pub fn new(cache_dir: PathBuf) -> Self {
        let regular_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans.ttf"))
            .unwrap_or_default();
        let bold_bytes = fs::read("/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf")
            .or_else(|_| fs::read("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf"))
            .unwrap_or_default();

        let font_regular = valid_font(regular_bytes).unwrap_or_else(|| {
            let fallback = fs::read("/usr/share/fonts/TTF/DejaVuSans.ttf")
                .expect("DejaVuSans font must exist");
            valid_font(fallback).expect("DejaVuSans font must be valid")
        });
        let font_bold = valid_font(bold_bytes).unwrap_or_else(|| font_regular.clone());

        Renderer {
            font_regular,
            font_bold,
            cache_dir,
        }
    }

    fn draw_char(
        img: &mut RgbaImage,
        scaler: &mut Scaler<'_>,
        glyph_id: u16,
        position: (f32, f32),
        color: Rgba<u8>,
    ) {
        if let Some(glyph) = Render::new(&[Source::Outline])
            .format(Format::Alpha)
            .render(scaler, glyph_id)
        {
            Self::draw_glyph(img, &glyph, position.0, position.1, color);
        }
    }

    fn draw_str(
        img: &mut RgbaImage,
        context: &mut ScaleContext,
        font_data: &[u8],
        s: &str,
        style: TextStyle,
    ) {
        let Some(font) = FontRef::from_index(font_data, 0) else {
            return;
        };
        let charmap = font.charmap();
        let metrics = font.glyph_metrics(&[]);
        let advance_scale = style.scale / font.metrics(&[]).units_per_em.max(1) as f32;
        let mut scaler = context.builder(font).size(style.scale).build();
        let mut position = style.position;
        for c in s.chars() {
            let glyph_id = charmap.map(c);
            Self::draw_char(img, &mut scaler, glyph_id, position, style.color);
            position.0 += metrics.advance_width(glyph_id) * advance_scale;
        }
    }

    fn draw_glyph(img: &mut RgbaImage, glyph: &Image, x: f32, baseline: f32, color: Rgba<u8>) {
        let width = glyph.placement.width as usize;
        let height = glyph.placement.height as usize;
        let left = x.floor() as i32 + glyph.placement.left;
        let top = baseline.ceil() as i32 - glyph.placement.top;

        for gy in 0..height {
            let py = top + gy as i32;
            if py < 0 || py as u32 >= img.height() {
                continue;
            }
            for gx in 0..width {
                let px = left + gx as i32;
                if px < 0 || px as u32 >= img.width() {
                    continue;
                }
                let alpha = glyph.data[gy * width + gx];
                if alpha == 0 {
                    continue;
                }

                let pixel = img.get_pixel_mut(px as u32, py as u32);
                let a = alpha as f32 / 255.0;
                for channel in 0..3 {
                    pixel[channel] =
                        ((1.0 - a) * pixel[channel] as f32 + a * color[channel] as f32) as u8;
                }
                pixel[3] = 255;
            }
        }
    }

    fn wrap_text(&self, text: &str, scale: f32, max_w: f32) -> Vec<String> {
        let Some(font) = FontRef::from_index(&self.font_regular, 0) else {
            return vec![text.to_owned()];
        };
        let charmap = font.charmap();
        let metrics = font.glyph_metrics(&[]);
        let advance_scale = scale / font.metrics(&[]).units_per_em.max(1) as f32;
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
                    .map(|c| metrics.advance_width(charmap.map(c)) * advance_scale)
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
        let path = self.cache_dir.join(format!("txt_{:x}.png", hash));

        if path.exists() {
            return path.to_string_lossy().into_owned();
        }

        let mut img = RgbaImage::from_pixel(CARD_W, CARD_H, BG_COLOR);
        let mut scale_context = ScaleContext::new();

        // Fill the header in the backing buffer to avoid per-pixel bounds checks.
        let header_bytes = CARD_W as usize * 64 * 4;
        let (header_pixels, _) = img.as_mut()[..header_bytes].as_chunks_mut::<4>();
        for pixel in header_pixels {
            pixel.copy_from_slice(&HEADER_BG.0);
        }

        // Header Border Line
        let border = Rgba([49, 50, 68, 255]);
        let border_start = header_bytes;
        let (border_pixels, _) =
            img.as_mut()[border_start..border_start + CARD_W as usize * 4].as_chunks_mut::<4>();
        for pixel in border_pixels {
            pixel.copy_from_slice(&border.0);
        }

        // Header Icon & Title
        let header_str = format!("{}  {}", icon, title);
        Self::draw_str(
            &mut img,
            &mut scale_context,
            &self.font_bold,
            &header_str,
            TextStyle {
                scale: 22.0,
                position: (24.0, 42.0),
                color: ACCENT_COLOR,
            },
        );

        if !sub.is_empty() {
            Self::draw_str(
                &mut img,
                &mut scale_context,
                &self.font_regular,
                sub,
                TextStyle {
                    scale: 16.0,
                    position: (24.0, 96.0),
                    color: MUTED_COLOR,
                },
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
                    &mut scale_context,
                    &self.font_regular,
                    "… (truncated)",
                    TextStyle {
                        scale: 18.0,
                        position: (24.0, y),
                        color: MUTED_COLOR,
                    },
                );
                break;
            }
            Self::draw_str(
                &mut img,
                &mut scale_context,
                &self.font_regular,
                line,
                TextStyle {
                    scale: 18.0,
                    position: (24.0, y),
                    color: FG_COLOR,
                },
            );
        }

        let _ = img.save(&path);
        path.to_string_lossy().into_owned()
    }

    pub fn render_pdf_preview(&self, pdf_path: &Path) -> Option<String> {
        let prefix = self.cache_dir.join(format!("pdf_{:x}", {
            let mut h = DefaultHasher::new();
            pdf_path.hash(&mut h);
            h.finish()
        }));
        let out_png = PathBuf::from(format!("{}-1.png", prefix.display()));

        if out_png.exists() {
            return Some(out_png.to_string_lossy().into_owned());
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
                prefix.to_str()?,
            ])
            .status()
            .ok()?;

        if status.success() && out_png.exists() {
            Some(self.optimize_image(&out_png.to_string_lossy()))
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn renders_text_with_loaded_font() {
        let cache_dir =
            std::env::temp_dir().join(format!("rofi-clipboard-card-test-{}", std::process::id()));
        fs::create_dir_all(&cache_dir).unwrap();

        let renderer = Renderer::new(cache_dir.clone());
        let path =
            renderer.render_text_card("󰆍", "Renderer test", "font migration", "A rendered body");
        let image = image::open(&path).unwrap().to_rgba8();

        assert_eq!(image.dimensions(), (CARD_W, CARD_H));
        assert!(image
            .pixels()
            .any(|pixel| { pixel[0] > 150 && pixel[2] > 150 && pixel[3] == 255 }));

        fs::remove_dir_all(cache_dir).unwrap();
    }
}
