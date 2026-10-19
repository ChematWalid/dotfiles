//! High-performance card image renderer using swash and image.

use anyhow::{bail, Result};
use image::imageops::FilterType;
use image::{ImageFormat, Rgba, RgbaImage};
use std::collections::hash_map::DefaultHasher;
use std::fs;
use std::hash::{Hash, Hasher};
use std::os::unix::fs::MetadataExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use swash::scale::{image::Image, Render, ScaleContext, Scaler, Source};
use swash::zeno::Format;
use swash::FontRef;

use crate::theme::{ACCENT_COLOR, BG_COLOR, CARD_H, CARD_W, FG_COLOR, HEADER_BG, MUTED_COLOR};

fn read_font(candidates: &[&str]) -> Result<Vec<u8>> {
    for path in candidates {
        if let Ok(data) = fs::read(path) {
            if FontRef::from_index(&data, 0).is_some() {
                return Ok(data);
            }
        }
    }
    bail!("no valid font found; tried {}", candidates.join(", "))
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
    pub fn new(cache_dir: PathBuf) -> Result<Self> {
        let font_regular = read_font(&[
            "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf",
            "/usr/share/fonts/TTF/DejaVuSans.ttf",
        ])?;
        let font_bold = read_font(&[
            "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf",
            "/usr/share/fonts/TTF/DejaVuSans-Bold.ttf",
        ])
        .unwrap_or_else(|_| font_regular.clone());

        Ok(Renderer {
            font_regular,
            font_bold,
            cache_dir,
        })
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
        let image_width = img.width() as usize;
        let left = x.floor() as i32 + glyph.placement.left;
        let top = baseline.ceil() as i32 - glyph.placement.top;
        let image_right = img.width() as i32;
        let image_bottom = img.height() as i32;
        let clipped_left = left.max(0);
        let clipped_top = top.max(0);
        let clipped_right = left.saturating_add(width as i32).min(image_right);
        let clipped_bottom = top.saturating_add(height as i32).min(image_bottom);
        if clipped_left >= clipped_right || clipped_top >= clipped_bottom {
            return;
        }

        let clipped_left = clipped_left as usize;
        let clipped_top = clipped_top as usize;
        let clipped_right = clipped_right as usize;
        let clipped_bottom = clipped_bottom as usize;
        let source_x = (clipped_left as i32 - left) as usize;
        let pixels = img.as_mut();

        for py in clipped_top..clipped_bottom {
            let gy = (py as i32 - top) as usize;
            let source_row = gy * width + source_x;
            let destination_start = (py * image_width + clipped_left) * 4;
            let destination_end = destination_start + (clipped_right - clipped_left) * 4;
            let row = &mut pixels[destination_start..destination_end];
            let (pixel_chunks, _) = row.as_chunks_mut::<4>();
            for (offset, pixel) in pixel_chunks.iter_mut().enumerate() {
                let alpha = glyph.data[source_row + offset];
                if alpha == 0 {
                    continue;
                }

                let alpha = alpha as u16;
                let inverse_alpha = 255 - alpha;
                for channel in 0..3 {
                    let blended =
                        pixel[channel] as u16 * inverse_alpha + color[channel] as u16 * alpha;
                    pixel[channel] = (blended / 255) as u8;
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

    pub fn render_text_card(
        &self,
        icon: &str,
        title: &str,
        sub: &str,
        text: &str,
    ) -> Result<String> {
        let mut hasher = DefaultHasher::new();
        icon.hash(&mut hasher);
        title.hash(&mut hasher);
        sub.hash(&mut hasher);
        text.hash(&mut hasher);
        let hash = hasher.finish();
        let path = self.cache_dir.join(format!("txt_{:x}.png", hash));

        if path.exists() {
            return Ok(path.to_string_lossy().into_owned());
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

        let temp_path = self
            .cache_dir
            .join(format!("txt_{hash}.{}.tmp", std::process::id()));
        img.save_with_format(&temp_path, ImageFormat::Png)?;
        if let Err(error) = fs::rename(&temp_path, &path) {
            let _ = fs::remove_file(temp_path);
            return Err(error.into());
        }
        Ok(path.to_string_lossy().into_owned())
    }

    pub fn render_pdf_preview(&self, pdf_path: &Path) -> Option<String> {
        let mut hasher = DefaultHasher::new();
        pdf_path.hash(&mut hasher);
        if let Ok(metadata) = pdf_path.metadata() {
            metadata.dev().hash(&mut hasher);
            metadata.ino().hash(&mut hasher);
            metadata.len().hash(&mut hasher);
            metadata.mtime().hash(&mut hasher);
            metadata.mtime_nsec().hash(&mut hasher);
        }
        let prefix = self.cache_dir.join(format!("pdf_{:x}", hasher.finish()));
        let out_png = PathBuf::from(format!("{}-1.png", prefix.display()));

        if out_png.exists() {
            return Some(self.optimize_image(&out_png.to_string_lossy()));
        }

        let output = Command::new("pdftoppm")
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
            .output();

        match output {
            Ok(output) if output.status.success() && out_png.exists() => {
                Some(self.optimize_image(&out_png.to_string_lossy()))
            }
            Ok(output) => {
                let stderr = String::from_utf8_lossy(&output.stderr);
                let _ = fs::remove_file(&out_png);
                if stderr.trim().is_empty() {
                    eprintln!(
                        "rofi-clipboard: pdftoppm failed with status {}",
                        output.status
                    );
                } else {
                    eprintln!("rofi-clipboard: pdftoppm failed: {}", stderr.trim());
                }
                None
            }
            Err(error) => {
                eprintln!("rofi-clipboard: could not start pdftoppm: {error}");
                None
            }
        }
    }

    pub fn optimize_image(&self, path: &str) -> String {
        let opt_path = format!("{}_opt.png", path);
        if Path::new(&opt_path).exists() {
            return opt_path;
        }

        let Ok((w, h)) = image::image_dimensions(path) else {
            return path.to_owned();
        };
        if w <= 1400 && h <= 1400 {
            return path.to_owned();
        }

        if let Ok(img) = image::open(path) {
            let ratio = (1400.0 / w as f32).min(1400.0 / h as f32);
            let nw = (w as f32 * ratio) as u32;
            let nh = (h as f32 * ratio) as u32;
            let resized = img.resize_exact(nw, nh, FilterType::Triangle);
            if resized.save(&opt_path).is_ok() {
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

        let renderer = Renderer::new(cache_dir.clone()).unwrap();
        let path = renderer
            .render_text_card("󰆍", "Renderer test", "font migration", "A rendered body")
            .unwrap();
        let image = image::open(&path).unwrap().to_rgba8();

        assert_eq!(image.dimensions(), (CARD_W, CARD_H));
        assert!(image
            .pixels()
            .any(|pixel| { pixel[0] > 150 && pixel[2] > 150 && pixel[3] == 255 }));

        fs::remove_dir_all(cache_dir).unwrap();
    }
}
