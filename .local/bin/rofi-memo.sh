#!/usr/bin/env bash
# ── rofi-memo.sh ──────────────────────────────────────────────────────────────
# Fast scratchpad note taker and viewer in Rofi with Catppuccin Mocha styling.
# Type text and press Enter to save a timestamped note.
# Select an existing note to copy it to clipboard.
# Select 'Open Notes in Editor' to edit the full file in Neovim.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

NOTES_DIR="${HOME}/Notes"
NOTES_FILE="${NOTES_DIR}/scratch.md"

mkdir -p "$NOTES_DIR"
touch "$NOTES_FILE"

ENTRIES=$(tac "$NOTES_FILE" 2>/dev/null | grep -v '^[[:space:]]*$' || true)
MENU_ITEMS="📖 Open Notes in Editor\n${ENTRIES}"

CHOICE=$(echo -e "$MENU_ITEMS" | rofi -dmenu -p "📝 Memo" -theme ~/.config/rofi/config.rasi)

[[ -z "$CHOICE" ]] && exit 0

if [[ "$CHOICE" == "📖 Open Notes in Editor" ]]; then
    kitty -e nvim "$NOTES_FILE" &
elif grep -Fxq "$CHOICE" "$NOTES_FILE" 2>/dev/null; then
    CLEAN_TEXT=$(echo "$CHOICE" | sed -E 's/^- \[[0-9 :-]+\] //')
    echo -n "$CLEAN_TEXT" | xclip -selection clipboard
    dunstify -a "Memo" -u low -i "accessories-text-editor" "Copied to Clipboard" "$CLEAN_TEXT"
else
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M")
    echo "- [${TIMESTAMP}] ${CHOICE}" >> "$NOTES_FILE"
    dunstify -a "Memo" -u low -i "accessories-text-editor" "Note Saved" "${CHOICE}"
fi
