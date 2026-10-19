//! Application Nerd Font icon registry.
//! Grouped by category for ease of future additions and edits.

use crate::config::{DEFAULT_ICON, IGNORE_CLASSES};
// An ordered registry keeps substring fallback deterministic. Exact matches are
// always considered first, so short names such as `code` cannot steal a longer
// application match.
const ICON_MAP: &[(&[&str], &str)] = &[
    // Terminals
    (&["kitty"], "󰆍"),
    (
        &[
            "alacritty",
            "xterm",
            "urxvt",
            "gnome-terminal",
            "terminator",
        ],
        "",
    ),
    // Browsers
    (&["google-chrome", "chromium", "brave-browser"], "󰊯"),
    (&["firefox", "librewolf", "zen-browser"], "󰈹"),
    // Chat and communication
    (
        &[
            "telegramdesktop",
            "telegram-desktop",
            "telegram",
            "ayugram",
            "64gram",
        ],
        "",
    ),
    (&["discord", "webcord", "vesktop"], "󰙯"),
    (&["slack"], "󰒱"),
    // Code, editors, and IDEs
    (&["antigravity"], "󰘦"),
    (&["vscodium", "code-oss", "cursor", "code"], "󰨞"),
    (
        &[
            "jetbrains-idea",
            "jetbrains-pycharm",
            "jetbrains-clion",
            "jetbrains-webstorm",
        ],
        "",
    ),
    (&["sublime_text", "subl"], "󰅪"),
    (&["neovim"], ""),
    (&["emacs"], ""),
    // Media and entertainment
    (&["spotify"], ""),
    (&["vlc", "mpv"], "󰕼"),
    (&["gimp", "inkscape"], ""),
    (&["obs-studio", "obs"], "󰑋"),
    (&["steam"], "󰓓"),
    // Utilities and file managers
    (&["thunar", "nautilus", "dolphin", "pcmanfm"], ""),
    (&["pavucontrol"], "󰕾"),
    (&["blueman-manager"], "󰂯"),
    (&["lxappearance"], "󰔎"),
    (&["postman"], "󱂛"),
    (&["dbeaver"], "󰆼"),
    (&["qbittorrent"], "󰇚"),
    // Mathematics and science
    (
        &[
            "kmplot", "kig", "labplot", "cantor", "geogebra", "maxima", "wxmaxima",
        ],
        "",
    ),
];

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
    let fields = [cls, inst, name].map(|field| field.to_lowercase());

    // Window class and instance are stable identifiers; titles are only a
    // fallback because they are user content and can contain incidental names.
    for exact in [&fields[0], &fields[1]] {
        for &(aliases, icon) in ICON_MAP {
            if aliases.iter().any(|alias| exact == alias) {
                return icon;
            }
        }
    }

    for field in &fields {
        for &(aliases, icon) in ICON_MAP {
            if aliases.iter().any(|alias| field.contains(alias)) {
                return icon;
            }
        }
    }
    DEFAULT_ICON
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_icon_lookup_terminals() {
        assert_eq!(get_icon("kitty", "kitty", "kitty"), "󰆍");
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
    fn test_icon_lookup_prefers_exact_app_class() {
        assert_eq!(
            get_icon("Code", "code", "Firefox - Visual Studio Code"),
            "󰨞"
        );
        assert_eq!(get_icon("kitty", "kitty", "Firefox documentation"), "󰆍");
    }

    #[test]
    fn test_icon_lookup_is_stable_for_overlapping_names() {
        assert_eq!(get_icon("obs-studio", "obs", "OBS"), "󰑋");
        assert_eq!(get_icon("vscodium", "code", "Code"), "󰨞");
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
