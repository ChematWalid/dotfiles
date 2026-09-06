#!/usr/bin/env bash
# ── lock.sh ───────────────────────────────────────────────────────────────────
# Catppuccin Mocha Aesthetic Lockscreen with i3lock-color.

set -euo pipefail

readonly BG_IMAGE="${HOME}/Downloads/catppuccin-wall-dark.jpg"
readonly LOCK_BG="${HOME}/.cache/lockscreen_blur.png"

# Generate high-quality blurred wallpaper if missing
if [[ ! -f "$LOCK_BG" && -f "$BG_IMAGE" ]]; then
    magick "$BG_IMAGE" -filter Gaussian -resize 25% -define filter:sigma=2.5 -resize 400% -fill "#11111b" -colorize 30% "$LOCK_BG" 2>/dev/null || true
fi

# Catppuccin Mocha Palette (Hex + Alpha)
readonly BASE="1e1e2ecc"
readonly SURFACE="313244cc"
readonly TEXT="cdd6f4ff"
readonly MAUVE="cba6f7ff"
readonly BLUE="89b4faff"
readonly GREEN="a6e3a1ff"
readonly RED="f38ba8ff"
readonly CLEAR="00000000"

i3lock \
  --nofork \
  --image="${LOCK_BG}" \
  --ignore-empty-password \
  --show-failed-attempts \
  --clock \
  --indicator \
  --time-str="%H:%M" \
  --time-font="JetBrainsMono Nerd Font" \
  --time-size=60 \
  --time-color="${TEXT}" \
  --date-str="%A, %d %B %Y" \
  --date-font="JetBrainsMono Nerd Font" \
  --date-size=18 \
  --date-color="${MAUVE}" \
  --greeter-text="🔒 Locked" \
  --greeter-font="JetBrainsMono Nerd Font" \
  --greeter-size=16 \
  --greeter-color="${BLUE}" \
  --verif-text="Verifying..." \
  --verif-font="JetBrainsMono Nerd Font" \
  --verif-size=16 \
  --verif-color="${BLUE}" \
  --wrong-text="Wrong Password" \
  --wrong-font="JetBrainsMono Nerd Font" \
  --wrong-size=16 \
  --wrong-color="${RED}" \
  --radius=130 \
  --ring-width=10 \
  --inside-color="${BASE}" \
  --ring-color="${MAUVE}" \
  --insidever-color="${SURFACE}" \
  --ringver-color="${BLUE}" \
  --insidewrong-color="${SURFACE}" \
  --ringwrong-color="${RED}" \
  --line-color="${CLEAR}" \
  --separator-color="${CLEAR}" \
  --keyhl-color="${GREEN}" \
  --bshl-color="${RED}" \
  --layout-color="${TEXT}" \
  --layout-font="JetBrainsMono Nerd Font"

# Re-apply keyboard rate and mouse settings after unlocking
"${HOME}/.local/bin/apply-input-settings.sh" --no-spawn &
