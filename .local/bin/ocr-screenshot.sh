#!/usr/bin/env bash
# ── ocr-screenshot.sh ─────────────────────────────────────────────────────────
# Fast, reliable screen region OCR using Flameshot/Maim + Tesseract.
# Extracts English & Arabic text, copies to clipboard & CopyQ, and notifies.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

readonly TESS_DIR="${HOME}/.local/share/tessdata"
export TESSDATA_PREFIX="$TESS_DIR"

TMP_RAW=$(mktemp /tmp/ocr_raw_XXXXXX.png)
TMP_OPT=$(mktemp /tmp/ocr_opt_XXXXXX.png)
trap 'rm -f "$TMP_RAW" "$TMP_OPT"' EXIT

# Ensure Flameshot background daemon is active
if ! pgrep -x flameshot >/dev/null 2>&1; then
    flameshot >/dev/null 2>&1 &
    sleep 0.15
fi

# 1. Capture screen region: Try Flameshot raw output first
if ! flameshot gui -r > "$TMP_RAW" 2>/dev/null || [[ ! -s "$TMP_RAW" ]]; then
    # Fallback to maim interactive region selector (click and drag)
    if ! maim -s "$TMP_RAW" 2>/dev/null || [[ ! -s "$TMP_RAW" ]]; then
        # User aborted capture (e.g. pressed Escape or right-clicked)
        exit 0
    fi
fi

# 2. Image Pre-processing for optimal OCR readability on screen fonts
if command -v magick >/dev/null 2>&1; then
    # 2x upscale with unsharp filter dramatically improves recognition of screen fonts
    magick "$TMP_RAW" -resize 200% -colorspace Gray -sharpen 0x1 "$TMP_OPT" 2>/dev/null || cp "$TMP_RAW" "$TMP_OPT"
else
    cp "$TMP_RAW" "$TMP_OPT"
fi

# 3. Execute Tesseract OCR (with fallback chain: eng+ara -> eng -> system default)
OCR_TEXT=""
if [[ -d "$TESS_DIR" ]]; then
    OCR_TEXT=$(tesseract --tessdata-dir "$TESS_DIR" "$TMP_OPT" stdout -l eng+ara 2>/dev/null || true)
    if [[ -z "$OCR_TEXT" ]]; then
        OCR_TEXT=$(tesseract --tessdata-dir "$TESS_DIR" "$TMP_OPT" stdout -l eng 2>/dev/null || true)
    fi
fi

if [[ -z "$OCR_TEXT" ]]; then
    OCR_TEXT=$(tesseract "$TMP_OPT" stdout 2>/dev/null || true)
fi

# 4. Clean up recognized text
CLEAN_TEXT=$(echo "$OCR_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

if [[ -z "$CLEAN_TEXT" ]]; then
    notify-send -u low -a "OCR" -i "dialog-information" "🔍 OCR Capture" "No text recognized in selected area."
    exit 0
fi

# 5. Copy to X11 clipboards & CopyQ history
if command -v xclip >/dev/null 2>&1; then
    printf "%s" "$CLEAN_TEXT" | xclip -selection clipboard 2>/dev/null || true
    printf "%s" "$CLEAN_TEXT" | xclip -selection primary 2>/dev/null || true
fi

if command -v copyq >/dev/null 2>&1; then
    copyq add "$CLEAN_TEXT" 2>/dev/null || true
fi

# 6. Notification with snippet preview
CHAR_COUNT=${#CLEAN_TEXT}
PREVIEW=$(echo "$CLEAN_TEXT" | head -n 3 | cut -c 1-120)
[[ ${#CLEAN_TEXT} -gt 120 ]] && PREVIEW+="..."

notify-send -a "OCR" -i "accessories-character-map" \
    "📋 Text Copied (${CHAR_COUNT} chars)" \
    "$PREVIEW"
