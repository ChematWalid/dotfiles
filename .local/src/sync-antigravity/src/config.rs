//! Filesystem path configuration for Antigravity synchronizer.

use std::path::PathBuf;

pub fn home_dir() -> PathBuf {
    std::env::var("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|_| PathBuf::from("/home/walid"))
}

pub struct SyncPaths {
    pub gui_dir: PathBuf,
    pub cli_dir: PathBuf,
    pub gui_convs: PathBuf,
    pub cli_convs: PathBuf,
    pub gui_brain: PathBuf,
    pub cli_brain: PathBuf,
    pub gui_proto: PathBuf,
    pub cli_db: PathBuf,
}

impl SyncPaths {
    pub fn new() -> Self {
        let home = home_dir();
        let gui_dir = home.join(".gemini/antigravity");
        let cli_dir = home.join(".gemini/antigravity-cli");

        let gui_convs = gui_dir.join("conversations");
        let cli_convs = cli_dir.join("conversations");

        let gui_brain = gui_dir.join("brain");
        let cli_brain = cli_dir.join("brain");

        let gui_proto = gui_dir.join("agyhub_summaries_proto.pb");
        let cli_db = cli_dir.join("conversation_summaries.db");

        Self {
            gui_dir,
            cli_dir,
            gui_convs,
            cli_convs,
            gui_brain,
            cli_brain,
            gui_proto,
            cli_db,
        }
    }
}
