#!/usr/bin/env bash
# ── ocr-screenshot.sh ─────────────────────────────────────────────────────────
# Captures a screen region, extracts text with Tesseract OCR (Eng + Ara),
# copies to clipboard & CopyQ history, and previews via Dunst notification.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

export TESSDATA_PREFIX="${HOME}/.local/share/tessdata:${TESSDATA_PREFIX:-/usr/share/tessdata}"

TMP_PNG=$(mktemp /tmp/ocr_capture_XXXXXX.png)
trap 'rm -f "$TMP_PNG"' EXIT

# Ensure Flameshot background daemon is running
if ! pgrep -x flameshot >/dev/null 2>&1; then
    flameshot >/dev/null 2>&1 &
    sleep 0.15
fi

# Attempt capture with Flameshot raw output
if ! flameshot gui -r > "$TMP_PNG" 2>/dev/null || [[ ! -s "$TMP_PNG" ]]; then
    # Fallback to maim interactive region capture if Flameshot was cancelled or errored
    if ! maim -s "$TMP_PNG" 2>/dev/null || [[ ! -s "$TMP_PNG" ]]; then
        # User cancelled capture (e.g. pressed Escape)
        exit 0
    fi
fi

# Run Tesseract OCR (English + Arabic)
OCR_TEXT=$(tesseract "$TMP_PNG" stdout -l eng+ara 2>/dev/null || tesseract "$TMP_PNG" stdout -l eng 2>/dev/null || true)

# Trim leading and trailing whitespace
CLEAN_TEXT=$(echo "$OCR_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ -z "$CLEAN_TEXT" ]]; then
    notify-send -u low -a "OCR" -i "dialog-information" "🔍 OCR Capture" "No text recognized in selected area."
    exit 0
fi

# Copy to X11 clipboard & primary selection
if command -v xclip >/dev/null 2>&1; then
    printf "%s" "$CLEAN_TEXT" | xclip -selection clipboard 2>/dev/null || true
    printf "%s" "$CLEAN_TEXT" | xclip -selection primary 2>/dev/null || true
fi

# Add to CopyQ clipboard manager
if command -v copyq >/dev/null 2>&1; then
    copyq add "$CLEAN_TEXT" 2>/dev/null || true
fi

# Count characters and preview notification
CHAR_COUNT=${#CLEAN_TEXT}
PREVIEW=$(echo "$CLEAN_TEXT" | head -n 3 | cut -c 1-120)
[[ ${#CLEAN_TEXT} -gt 120 ]] && PREVIEW+="..."

notify-send -a "OCR" -i "accessories-character-map" \
    "📋 Text Copied (${CHAR_COUNT} chars)" \
    "$PREVIEW"
