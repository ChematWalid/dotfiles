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
