//! CopyQ query and clipboard dispatch operations.

use anyhow::{Context, Result};
use serde::Deserialize;
use std::process::Command;
use std::thread;
use std::time::Duration;

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

pub fn fetch_items() -> Result<Vec<CopyQItem>> {
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
                var f = new File('/tmp/copyq_thumbs/' + rawImg);
                if (!f.exists() && f.open(File.WriteOnly)) {{ f.write(b); f.close(); }}
            }}
            res.push({{i: i, isImage: isImage, isFiles: isFiles, text: rawText, rawImg: rawImg}});
        }}
        JSON.stringify(res);
    "#,
        crate::theme::MAX_ITEMS
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

pub fn select_and_paste(item_idx: usize) {
    let _ = Command::new("copyq")
        .args(["select", &item_idx.to_string()])
        .status();
    thread::sleep(Duration::from_millis(80));
    let _ = Command::new("copyq").arg("paste").status();
}
