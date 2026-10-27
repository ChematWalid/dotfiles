use std::collections::HashSet;
use std::fs::{self, File};
use std::io::Read;
use std::path::{Path, PathBuf};

const SUPPORTED_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "webp"];

pub fn is_supported_image(path: &Path) -> bool {
    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        let ext_lower = ext.to_ascii_lowercase();
        return SUPPORTED_EXTENSIONS.iter().any(|&e| e == ext_lower);
    }
    false
}

pub fn is_valid_image_magic(path: &Path) -> bool {
    let mut file = match File::open(path) {
        Ok(f) => f,
        Err(_) => return false,
    };
    let mut header = [0u8; 12];
    let n = match file.read(&mut header) {
        Ok(n) => n,
        Err(_) => return false,
    };
    if n < 3 {
        return false;
    }

    // JPEG: FF D8 FF
    if header.starts_with(&[0xff, 0xd8, 0xff]) {
        return true;
    }
    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if n >= 8 && header.starts_with(&[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]) {
        return true;
    }
    // WEBP: RIFF....WEBP
    if n >= 12 && &header[0..4] == b"RIFF" && &header[8..12] == b"WEBP" {
        return true;
    }

    false
}

pub fn scan_wallpapers(root: &Path, max_depth: usize) -> Vec<PathBuf> {
    let mut results = Vec::new();
    let mut visited = HashSet::new();

    if let Ok(canon) = fs::canonicalize(root) {
        visited.insert(canon);
    }

    scan_dir_recursive(root, 1, max_depth, &mut visited, &mut results);
    results.sort();
    results.dedup();
    results
}

fn scan_dir_recursive(
    dir: &Path,
    current_depth: usize,
    max_depth: usize,
    visited: &mut HashSet<PathBuf>,
    results: &mut Vec<PathBuf>,
) {
    if current_depth > max_depth {
        return;
    }

    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };

    for entry in entries.flatten() {
        let path = entry.path();
        // Follow symlinks by querying metadata (not symlink_metadata)
        let metadata = match fs::metadata(&path) {
            Ok(m) => m,
            Err(_) => continue,
        };

        if metadata.is_file() {
            if is_supported_image(&path) {
                results.push(path);
            }
        } else if metadata.is_dir() {
            // Prevent symlink cycles
            if let Ok(canon) = fs::canonicalize(&path) {
                if !visited.insert(canon) {
                    continue; // Already visited
                }
            }
            scan_dir_recursive(&path, current_depth + 1, max_depth, visited, results);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs::File;

    #[test]
    fn test_extension_matching() {
        assert!(is_supported_image(Path::new("test.jpg")));
        assert!(is_supported_image(Path::new("test.JPG")));
        assert!(is_supported_image(Path::new("test.png")));
        assert!(is_supported_image(Path::new("test.PNG")));
        assert!(is_supported_image(Path::new("test.jpeg")));
        assert!(is_supported_image(Path::new("test.webp")));
        assert!(!is_supported_image(Path::new("test.txt")));
        assert!(!is_supported_image(Path::new("test.sh")));
        assert!(!is_supported_image(Path::new("test")));
    }

    #[test]
    fn test_magic_bytes_detection() {
        let temp_dir = std::env::temp_dir().join(format!("wp_magic_test_{}", std::process::id()));
        let _ = fs::create_dir_all(&temp_dir);

        let png_file = temp_dir.join("valid.png");
        let _ = fs::write(&png_file, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
        assert!(is_valid_image_magic(&png_file));

        let jpg_file = temp_dir.join("valid.jpg");
        let _ = fs::write(&jpg_file, [0xff, 0xd8, 0xff, 0xe0, 0x00]);
        assert!(is_valid_image_magic(&jpg_file));

        let fake_file = temp_dir.join("fake.png");
        let _ = fs::write(&fake_file, "this is not an image");
        assert!(!is_valid_image_magic(&fake_file));

        let empty_file = temp_dir.join("empty.png");
        let _ = fs::write(&empty_file, "");
        assert!(!is_valid_image_magic(&empty_file));

        let _ = fs::remove_dir_all(&temp_dir);
    }

    #[test]
    fn test_scanner_depth_and_filter() {
        let temp_dir = std::env::temp_dir().join(format!("wp_scan_test_{}", std::process::id()));
        let _ = fs::remove_dir_all(&temp_dir);
        let l1 = temp_dir.join("d1");
        let l2 = l1.join("d2");
        let l3 = l2.join("d3");
        let l4 = l3.join("d4");
        fs::create_dir_all(&l4).unwrap();

        File::create(temp_dir.join("root.png")).unwrap();
        File::create(temp_dir.join("ignored.txt")).unwrap();
        File::create(l1.join("level1.jpg")).unwrap();
        File::create(l2.join("level2.webp")).unwrap();
        File::create(l3.join("level3.jpeg")).unwrap();
        File::create(l4.join("level4_too_deep.png")).unwrap();

        let scanned = scan_wallpapers(&temp_dir, 3);
        let names: Vec<String> = scanned
            .iter()
            .map(|p| p.file_name().unwrap().to_str().unwrap().to_string())
            .collect();

        assert!(names.contains(&"root.png".to_string()));
        assert!(names.contains(&"level1.jpg".to_string()));
        assert!(names.contains(&"level2.webp".to_string()));
        // level 3 is at depth 4 from root, exceeds maxdepth 3 (3 folder levels: root, d1, d2)
        assert!(!names.contains(&"level3.jpeg".to_string()));
        assert!(!names.contains(&"level4_too_deep.png".to_string()));
        assert!(!names.contains(&"ignored.txt".to_string()));

        let _ = fs::remove_dir_all(&temp_dir);
    }

    #[test]
    fn test_scanner_symlink_cycle_and_dedup() {
        let temp_dir = std::env::temp_dir().join(format!("wp_symlink_test_{}", std::process::id()));
        let _ = fs::remove_dir_all(&temp_dir);
        let sub = temp_dir.join("sub");
        fs::create_dir_all(&sub).unwrap();

        let real_img = sub.join("real.png");
        File::create(&real_img).unwrap();

        // Create cyclical symlink: sub/loop -> temp_dir
        #[cfg(unix)]
        {
            use std::os::unix::fs::symlink;
            let _ = symlink(&temp_dir, sub.join("loop"));
            let _ = symlink(&real_img, temp_dir.join("alias.png"));
        }

        let scanned = scan_wallpapers(&temp_dir, 3);
        // Should not loop infinitely and should find images
        assert!(!scanned.is_empty());

        let _ = fs::remove_dir_all(&temp_dir);
    }
}

