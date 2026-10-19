#!/usr/bin/env bash
# ── ocr-screenshot.sh ─────────────────────────────────────────────────────────
# Fast, reliable screen region OCR using Flameshot/Maim + Tesseract.
# Extracts English & Arabic text, copies to clipboard & CopyQ, and notifies.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

readonly TESS_DIR="${HOME}/.local/share/tessdata"

notify_user() {
    local urgency="$1" title="$2" body="$3" icon="${4:-}"
    if command -v notify-send >/dev/null 2>&1; then
        if [[ -n "$icon" ]]; then
            notify-send -u "$urgency" -a "OCR" -i "$icon" "$title" "$body" || true
        else
            notify-send -u "$urgency" -a "OCR" "$title" "$body" || true
        fi
    else
        printf 'ocr-screenshot: %s: %s\n' "$title" "$body" >&2
    fi
}

if ! command -v tesseract >/dev/null 2>&1; then
    notify_user critical "OCR unavailable" "Tesseract is not installed or not on PATH."
    exit 127
fi

TMP_RAW=$(mktemp /tmp/ocr_raw_XXXXXX.png)
TMP_OPT=$(mktemp /tmp/ocr_opt_XXXXXX.png)
trap 'rm -f "$TMP_RAW" "$TMP_OPT"' EXIT

# 1. Capture screen region: Try Flameshot raw output first
if ! command -v flameshot >/dev/null 2>&1 && ! command -v maim >/dev/null 2>&1; then
    notify_user critical "OCR capture unavailable" "Install Flameshot or maim to select a screen region."
    exit 127
fi

if ! flameshot gui -r > "$TMP_RAW" 2>/dev/null || [[ ! -s "$TMP_RAW" ]]; then
    # Fallback to maim interactive region selector (click and drag)
    if ! command -v maim >/dev/null 2>&1; then
        notify_user critical "OCR capture failed" "Flameshot did not return a selected image and maim is unavailable."
        exit 1
    fi
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
OCR_RAN=false
if [[ -d "$TESS_DIR" ]]; then
    if OCR_TEXT=$(tesseract --tessdata-dir "$TESS_DIR" "$TMP_OPT" stdout -l eng+ara 2>/dev/null); then
        OCR_RAN=true
    fi
    if [[ -z "$OCR_TEXT" ]]; then
        if OCR_TEXT=$(tesseract --tessdata-dir "$TESS_DIR" "$TMP_OPT" stdout -l eng 2>/dev/null); then
            OCR_RAN=true
        fi
    fi
fi

if [[ -z "$OCR_TEXT" ]]; then
    # Keep the system-data fallback independent from the shell's custom prefix.
    if OCR_TEXT=$(env -u TESSDATA_PREFIX tesseract "$TMP_OPT" stdout 2>/dev/null); then
        OCR_RAN=true
    fi
fi

# 4. Clean up recognized text
CLEAN_TEXT="${OCR_TEXT#"${OCR_TEXT%%[![:space:]]*}"}"
CLEAN_TEXT="${CLEAN_TEXT%"${CLEAN_TEXT##*[![:space:]]}"}"

if [[ -z "$CLEAN_TEXT" ]]; then
    if [[ "$OCR_RAN" == false ]]; then
        notify_user critical "OCR failed" "Tesseract could not load usable language data or process the selected image."
        exit 1
    fi
    notify_user low "🔍 OCR Capture" "No text recognized in selected area." "dialog-information"
    exit 0
fi

# 5. Copy to X11 clipboards & CopyQ history
COPIED=false
if command -v xclip >/dev/null 2>&1; then
    if printf '%s' "$CLEAN_TEXT" | xclip -selection clipboard 2>/dev/null; then
        COPIED=true
    fi
    if printf '%s' "$CLEAN_TEXT" | xclip -selection primary 2>/dev/null; then
        COPIED=true
    fi
fi

if command -v copyq >/dev/null 2>&1; then
    if copyq add "$CLEAN_TEXT" 2>/dev/null; then
        COPIED=true
    fi
fi

# 6. Notification with snippet preview
CHAR_COUNT=${#CLEAN_TEXT}
mapfile -tn 3 PREVIEW_LINES <<< "$CLEAN_TEXT"
PREVIEW=""
for line in "${PREVIEW_LINES[@]}"; do
    [[ -n "$PREVIEW" ]] && PREVIEW+=$'\n'
    PREVIEW+="${line:0:120}"
done
[[ ${#CLEAN_TEXT} -gt 120 ]] && PREVIEW+="..."

if [[ "$COPIED" == true ]]; then
    notify_user normal "📋 Text Copied (${CHAR_COUNT} chars)" "$PREVIEW" \
        "accessories-character-map"
else
    notify_user critical "OCR text not copied (${CHAR_COUNT} chars)" \
        "Clipboard backends failed or are unavailable. Text starts with: ${PREVIEW}"
fi
