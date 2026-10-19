//! Filesystem path configuration for Antigravity synchronizer.

use std::path::PathBuf;
use std::{env, io};

pub struct SyncPaths {
    pub workspace_dir: PathBuf,
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
    pub fn new() -> io::Result<Self> {
        let home = env::var_os("HOME")
            .map(PathBuf::from)
            .filter(|path| path.is_absolute())
            .ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::NotFound,
                    "HOME is unset or not an absolute path",
                )
            })?;
        let gui_dir = home.join(".gemini/antigravity");
        let cli_dir = home.join(".gemini/antigravity-cli");

        let gui_convs = gui_dir.join("conversations");
        let cli_convs = cli_dir.join("conversations");

        let gui_brain = gui_dir.join("brain");
        let cli_brain = cli_dir.join("brain");

        let gui_proto = gui_dir.join("agyhub_summaries_proto.pb");
        let cli_db = cli_dir.join("conversation_summaries.db");

        Ok(Self {
            workspace_dir: home.join("E/Documents"),
            gui_dir,
            cli_dir,
            gui_convs,
            cli_convs,
            gui_brain,
            cli_brain,
            gui_proto,
            cli_db,
        })
    }
}
