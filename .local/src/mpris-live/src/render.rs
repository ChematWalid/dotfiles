//! Text formatting, marquee slicing, and Polybar formatting with click actions.

use crate::config::{
    COLOR_BLUE, COLOR_GREEN, COLOR_PINK, COLOR_TEXT, COLOR_YELLOW, ICON_NEXT, ICON_NOTE,
    ICON_PAUSE_BTN, ICON_PLAY_BTN, ICON_PREV, MAX_CHARS, SEPARATOR,
};
use crate::state::MediaState;

pub fn get_marquee_slice(text: &str, offset: usize, hovering: bool) -> String {
    let chars: Vec<char> = text.chars().collect();
    if chars.len() <= MAX_CHARS {
        return text.to_string();
    }
    if !hovering {
        let prefix: String = chars.iter().take(MAX_CHARS - 1).collect();
        return format!("{}…", prefix);
    }
    let sep_chars: Vec<char> = SEPARATOR.chars().collect();
    let mut stream: Vec<char> = chars.clone();
    stream.extend_from_slice(&sep_chars);
    let stream_len = stream.len();
    let idx = offset % stream_len;
    stream.iter().cycle().skip(idx).take(MAX_CHARS).collect()
}

pub fn render_polybar(state: &MediaState, scroll_pos: usize, hovering: bool) -> String {
    if state.player.is_empty() || state.status == "Stopped" || state.full_text.is_empty() {
        return String::new();
    }

    let (play_icon, play_color) = if state.status == "Playing" {
        (ICON_PAUSE_BTN, COLOR_GREEN)
    } else {
        (ICON_PLAY_BTN, COLOR_YELLOW)
    };

    let display = get_marquee_slice(&state.full_text, scroll_pos, hovering);
    let p = &state.player;

    format!(
        "%{{T4}}%{{F{COLOR_BLUE}}}%{{A1:playerctl -p {p} previous 2>/dev/null:}}{ICON_PREV}%{{A}}%{{F-}}  \
         %{{A1:playerctl -p {p} play-pause 2>/dev/null:}}%{{F{play_color}}}{play_icon}%{{F-}}%{{A}}  \
         %{{F{COLOR_BLUE}}}%{{A1:playerctl -p {p} next 2>/dev/null:}}{ICON_NEXT}%{{A}}%{{F-}}%{{T-}}   \
         %{{F{COLOR_PINK}}}{ICON_NOTE}%{{F-}} %{{F{COLOR_TEXT}}}{display}%{{F-}}"
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_marquee_short_text() {
        let text = "Short";
        assert_eq!(get_marquee_slice(text, 0, false), "Short");
        assert_eq!(get_marquee_slice(text, 0, true), "Short");
    }

    #[test]
    fn test_marquee_truncation_without_hover() {
        let long_text = "This is a very long media title that exceeds eighteen chars";
        let sliced = get_marquee_slice(long_text, 0, false);
        assert!(sliced.ends_with('…'));
        assert_eq!(sliced.chars().count(), MAX_CHARS);
    }

    #[test]
    fn test_marquee_hover_cyclic() {
        let long_text = "This is a very long media title that exceeds eighteen chars";
        let slice0 = get_marquee_slice(long_text, 0, true);
        let slice1 = get_marquee_slice(long_text, 1, true);
        assert_eq!(slice0.chars().count(), MAX_CHARS);
        assert_eq!(slice1.chars().count(), MAX_CHARS);
        assert_ne!(slice0, slice1);
    }

    #[test]
    fn test_render_polybar_empty() {
        let empty_state = MediaState::default();
        assert_eq!(render_polybar(&empty_state, 0, false), "");
    }

    #[test]
    fn test_render_polybar_playing() {
        let state = MediaState {
            player: "spotify".to_string(),
            status: "Playing".to_string(),
            full_text: "Artist - Song".to_string(),
        };
        let out = render_polybar(&state, 0, false);
        assert!(out.contains("Artist - Song"));
        assert!(out.contains("playerctl -p spotify"));
    }
}
