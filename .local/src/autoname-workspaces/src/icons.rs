//! Application Nerd Font icon registry.
//! Grouped by category for ease of future additions and edits.

use crate::config::{DEFAULT_ICON, IGNORE_CLASSES};
use std::collections::HashMap;
use std::sync::LazyLock;

static ICON_MAP: LazyLock<HashMap<&'static str, &'static str>> = LazyLock::new(|| {
    let mut m = HashMap::new();

    // ── Terminals ────────────────────────────────────────────────────────────
    m.insert("kitty", "");
    m.insert("alacritty", "");
    m.insert("xterm", "");
    m.insert("urxvt", "");
    m.insert("gnome-terminal", "");
    m.insert("terminator", "");

    // ── Browsers ─────────────────────────────────────────────────────────────
    m.insert("google-chrome", "󰊯");
    m.insert("chromium", "󰊯");
    m.insert("firefox", "󰈹");
    m.insert("librewolf", "󰈹");
    m.insert("zen-browser", "󰈹");
    m.insert("brave-browser", "󰊯");

    // ── Chat & Communication ─────────────────────────────────────────────────
    m.insert("telegramdesktop", "");
    m.insert("telegram-desktop", "");
    m.insert("telegram", "");
    m.insert("ayugram", "");
    m.insert("64gram", "");
    m.insert("discord", "󰙯");
    m.insert("webcord", "󰙯");
    m.insert("vesktop", "󰙯");
    m.insert("slack", "󰒱");

    // ── Code, Editors & IDEs ─────────────────────────────────────────────────
    m.insert("antigravity", "󰘦");
    m.insert("code", "󰨞");
    m.insert("vscodium", "󰨞");
    m.insert("code-oss", "󰨞");
    m.insert("cursor", "󰨞");
    m.insert("jetbrains-idea", "");
    m.insert("jetbrains-pycharm", "");
    m.insert("jetbrains-clion", "");
    m.insert("jetbrains-webstorm", "");
    m.insert("subl", "󰅪");
    m.insert("sublime_text", "󰅪");
    m.insert("emacs", "");
    m.insert("neovim", "");

    // ── Media & Entertainment ────────────────────────────────────────────────
    m.insert("spotify", "");
    m.insert("vlc", "󰕼");
    m.insert("mpv", "󰕼");
    m.insert("gimp", "");
    m.insert("inkscape", "");
    m.insert("obs", "󰑋");
    m.insert("obs-studio", "󰑋");
    m.insert("steam", "󰓓");

    // ── Utilities & File Managers ────────────────────────────────────────────
    m.insert("thunar", "");
    m.insert("nautilus", "");
    m.insert("dolphin", "");
    m.insert("pcmanfm", "");
    m.insert("pavucontrol", "󰕾");
    m.insert("blueman-manager", "󰂯");
    m.insert("lxappearance", "󰔎");
    m.insert("postman", "󱂛");
    m.insert("dbeaver", "󰆼");
    m.insert("qbittorrent", "󰇚");

    // ── Mathematics & Science ────────────────────────────────────────────────
    m.insert("kmplot", "");
    m.insert("kig", "");
    m.insert("labplot", "");
    m.insert("cantor", "");
    m.insert("geogebra", "");
    m.insert("maxima", "");
    m.insert("wxmaxima", "");

    m
});

pub fn is_ignored(cls: &str, inst: &str, name: &str) -> bool {
    let lower_cls = cls.to_lowercase();
    let lower_inst = inst.to_lowercase();
    let lower_name = name.to_lowercase();

    for ign in IGNORE_CLASSES {
        if lower_cls.contains(ign) || lower_inst.contains(ign) || lower_name.contains(ign) {
            return true;
        }
    }
    false
}

pub fn get_icon(cls: &str, inst: &str, name: &str) -> &'static str {
    let lower_cls = cls.to_lowercase();
    let lower_inst = inst.to_lowercase();
    let lower_name = name.to_lowercase();

    for (&key, &icon) in ICON_MAP.iter() {
        if lower_cls.contains(key) || lower_inst.contains(key) || lower_name.contains(key) {
            return icon;
        }
    }
    DEFAULT_ICON
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_icon_lookup_terminals() {
        assert_eq!(get_icon("kitty", "kitty", "kitty"), "");
        assert_eq!(get_icon("Alacritty", "alacritty", ""), "");
    }

    #[test]
    fn test_icon_lookup_browsers() {
        assert_eq!(get_icon("Google-chrome", "google-chrome", ""), "󰊯");
        assert_eq!(get_icon("Brave-browser", "", ""), "󰊯");
        assert_eq!(get_icon("firefox", "Navigator", "Mozilla Firefox"), "󰈹");
    }

    #[test]
    fn test_icon_lookup_editors() {
        assert_eq!(get_icon("Code", "code", "Visual Studio Code"), "󰨞");
        assert_eq!(get_icon("antigravity", "antigravity", "Antigravity"), "󰘦");
    }

    #[test]
    fn test_ignored_classes() {
        assert!(is_ignored("polybar", "polybar", "bar"));
        assert!(is_ignored("conky", "conky", "conky"));
        assert!(is_ignored("dunst", "", ""));
        assert!(!is_ignored("kitty", "kitty", "terminal"));
    }

    #[test]
    fn test_fallback_icon() {
        assert_eq!(get_icon("non_existent_app_12345", "", ""), DEFAULT_ICON);
    }
}
