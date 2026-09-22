#!/usr/bin/env bash
# Regenerate the preview images used by the READMEs.
# Author : Dr. Denys Dutykh — Khalifa University, Abu Dhabi, UAE  <https://www.denys-dutykh.com/>
# License: MIT — see LICENSE at the repository root
#
# The previews cannot be plain code blocks: both themes use Nerd Font glyphs from the
# private-use area, which GitHub's web font renders as empty boxes. So we render the real
# ANSI output to PNG with the actual font, once per colour scheme.
#
# Requires: python3 with Pillow + fontTools, a Nerd Font, starship, jq.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

for theme in dark light; do
  # Claude Code status line — force the theme so each image uses the right palette
  printf 'ICONS=nerd\nTHEME=%s\nLINES=3\nRESPONSIVE=1\n' "$theme" > "$tmp/sl.conf"
  CLAUDE_STATUSLINE_CONF="$tmp/sl.conf" \
    bash "$repo/claude/statusline-command.sh" --demo nerd 118 > "$tmp/sl.ansi"
  python3 "$here/ansi2png.py" "$here/claude-statusline-$theme.png" "$theme" < "$tmp/sl.ansi"

  # Starship prompt — rendered inside a clean clone so the image is deterministic
  # (a dirty working tree would add git-status counters and change on every run).
  [[ -d $tmp/my-cli-config ]] || git clone -q "$repo" "$tmp/my-cli-config"
  (
    cd "$tmp/my-cli-config"
    STARSHIP_CONFIG="$repo/starship/starship.toml" starship prompt --status 0 --cmd-duration 3000
  ) > "$tmp/star.ansi"
  python3 "$here/ansi2png.py" "$here/starship-prompt-$theme.png" "$theme" < "$tmp/star.ansi"
done

command -v optipng >/dev/null && optipng -quiet -o2 "$here"/*.png || true
echo "✓ previews regenerated in $here"
