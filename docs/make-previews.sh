#!/usr/bin/env bash
# Regenerate the preview images used by the READMEs.
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
#
#   docs/make-previews.sh                      all the previews
#   docs/make-previews.sh terminal             only those named: claude, starship, terminal
#
# The previews cannot be plain code blocks: both themes use Nerd Font glyphs from the
# private-use area, which GitHub's web font renders as empty boxes. So we render the real
# ANSI output to PNG with the actual font, once per colour scheme.
#
# The images are public, so they show a neutral user on a neutral machine (you@laptop): both
# components run with a temporary HOME that holds a clean clone at ~/workspace/my-cli-config
# (the folder the status line's demo shows; a clean tree keeps the git segments identical from
# run to run), a throwaway Python environment named demo, and no SSH or STARSHIP_SHELL variables
# (the latter would wrap the colours in the escapes of a bash prompt).
#
# The terminal previews show the made-up session of terminal-demo.sh in the theme of Ghostty,
# tokyo-night, and in its light companion, with the colours read from the theme files.
#
# Requires: python3 with Pillow + fontTools, a Nerd Font, starship, jq. The terminal previews
# are complete with eza and JuliaMono, and degrade without them.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

want=("$@")
((${#want[@]})) || want=(claude starship terminal)
for name in "${want[@]}"; do
  case $name in
    claude|starship|terminal) ;;
    *) echo "usage: make-previews.sh [claude] [starship] [terminal]" >&2; exit 2 ;;
  esac
done
wanted() { local w; for w in "${want[@]}"; do [[ $w == "$1" ]] && return 0; done; return 1; }
written=()

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

demo_home="$tmp/home"
mkdir -p "$demo_home/workspace" "$tmp/run"
git clone -q "$repo" "$demo_home/workspace/my-cli-config"
python3 -m venv --without-pip "$tmp/venvs/demo"
neutral=(env -u SSH_CONNECTION -u SSH_CLIENT -u SSH_TTY -u CONDA_DEFAULT_ENV -u STARSHIP_SHELL
         HOME="$demo_home" USER=you LOGNAME=you HOSTNAME=laptop XDG_RUNTIME_DIR="$tmp/run"
         VIRTUAL_ENV="$tmp/venvs/demo" PATH="$tmp/venvs/demo/bin:$PATH")
# Starship reads the login from the system rather than from $USER: an alias shows it as "you".
# The prompt shows the user name only over SSH or for another user, so its pictures run with the
# real login in LOGNAME and show no name at all, as on a local machine.
sed "/^\[username\]/a aliases = { \"$(id -un)\" = \"you\" }" \
  "$repo/starship/starship.toml" > "$tmp/starship.toml"

for theme in dark light; do
  if wanted claude; then
    # Claude Code status line, with the theme forced so that each image uses the right palette.
    # The first pass records the processor counters, so that the second can show the cpu load.
    printf 'ICONS=nerd\nTHEME=%s\nLINES=3\nRESPONSIVE=1\n' "$theme" > "$tmp/sl.conf"
    for _ in 1 2; do
      "${neutral[@]}" CLAUDE_STATUSLINE_CONF="$tmp/sl.conf" \
        bash "$repo/claude/statusline-command.sh" --demo nerd 118 > "$tmp/sl.ansi"
    done
    python3 "$here/ansi2png.py" "$here/claude-statusline-$theme.png" "$theme" < "$tmp/sl.ansi"
    written+=("$here/claude-statusline-$theme.png")
  fi

  if wanted starship; then
    # Starship prompt, rendered inside the clean clone.
    (
      cd "$demo_home/workspace/my-cli-config"
      "${neutral[@]}" LOGNAME="$(id -un)" STARSHIP_CONFIG="$tmp/starship.toml" \
        starship prompt --status 0 --cmd-duration 3000
    ) > "$tmp/star.ansi"
    python3 "$here/ansi2png.py" "$here/starship-prompt-$theme.png" "$theme" < "$tmp/star.ansi"
    written+=("$here/starship-prompt-$theme.png")
  fi

  if wanted terminal; then
    # A short session in the theme of Ghostty and its light companion, 70 columns wide, without
    # the Python environment.
    case $theme in dark) scheme=tokyo-night ;; *) scheme=tokyo-night-day ;; esac
    "${neutral[@]}" env -u VIRTUAL_ENV LOGNAME="$(id -un)" STARSHIP_CONFIG="$tmp/starship.toml" \
      bash "$here/terminal-demo.sh" 70 > "$tmp/term.ansi" < /dev/null
    python3 "$here/ansi2png.py" "$here/terminal-$theme.png" "$theme" "$repo/ghostty/themes/$scheme" < "$tmp/term.ansi"
    written+=("$here/terminal-$theme.png")
  fi
done

command -v optipng >/dev/null && optipng -quiet -o2 "${written[@]}" || true
echo "✓ previews regenerated in $here: ${want[*]}"
