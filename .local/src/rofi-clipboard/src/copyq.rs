//! CopyQ query and clipboard dispatch operations.

use anyhow::{bail, Context, Result};
use serde::Deserialize;
use std::path::Path;
use std::process::Command;

#[derive(Debug, Deserialize)]
pub struct CopyQItem {
    pub i: usize,
    #[serde(rename = "isImage")]
    pub is_image: bool,
    #[serde(rename = "isFiles")]
    pub is_files: bool,
    pub text: String,
    #[serde(rename = "rawImg")]
    pub raw_img: String,
}

pub fn fetch_items(cache_dir: &Path) -> Result<Vec<CopyQItem>> {
    let cache_dir = cache_dir.to_string_lossy();
    let cache_dir_js = serde_json::to_string(cache_dir.as_ref())?;
    let js = format!(
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
                var f = new File({} + '/' + rawImg);
                if (!f.exists() && f.open(File.WriteOnly)) {{ f.write(b); f.close(); }}
            }}
            res.push({{i: i, isImage: isImage, isFiles: isFiles, text: rawText, rawImg: rawImg}});
        }}
        JSON.stringify(res);
    "#,
        crate::theme::MAX_ITEMS,
        cache_dir_js,
    );

    let output = Command::new("copyq")
        .args(["eval", &js])
        .output()
        .context("Failed to run copyq eval")?;

    let out_str = String::from_utf8_lossy(&output.stdout);
    if out_str.trim().is_empty() {
        return Ok(Vec::new());
    }

    serde_json::from_str(&out_str).context("Failed to parse CopyQ JSON output")
}

pub fn select_and_paste(item_idx: usize) -> Result<()> {
    let script = format!("select({item_idx}); paste();");
    let status = Command::new("copyq").args(["eval", &script]).status();
    let status = status.context("Failed to run CopyQ selection and paste")?;
    if !status.success() {
        bail!("CopyQ failed to select and paste clipboard item {item_idx}");
    }
    Ok(())
}
