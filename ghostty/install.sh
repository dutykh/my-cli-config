#!/usr/bin/env bash
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
#
# Install / update the Ghostty configuration on this machine: the shared settings and the colour
# themes are symlinked, and the settings of the machine are written once.
#   git clone https://github.com/dutykh/my-cli-config.git ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
# Re-running is safe: a second run changes nothing. Updating later is just `git pull`.
# The default terminal of the desktop is never changed here: the line that does it is printed.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
base=${XDG_CONFIG_HOME:-$HOME/.config}
cfg_dir="$base/ghostty"

command -v ghostty >/dev/null || {
  echo "• ghostty is not installed: nothing linked"
  echo "  install:  sudo apt install ghostty        (Ubuntu 26.04 or later)"
  echo "         or https://ghostty.org/docs/install/binary, then run this installer again"
  exit 0
}

stamp=$(date +%Y%m%d-%H%M%S)

# link SOURCE TARGET: leave a right link alone, back up a real file that holds something.
link() {
  local source=$1 target=$2
  if [[ -L $target && $(readlink "$target") == "$source" ]]; then
    echo "= $target"
    return 0
  fi
  if [[ -d $target && ! -L $target ]]; then
    echo "✗ $target is a folder: left alone"
    return 1
  fi
  if [[ -s $target && ! -L $target ]]; then
    cp -a "$target" "$target.bak.$stamp"
    echo "• backed up existing file → $target.bak.$stamp"
  fi
  ln -sfn "$source" "$target"
  echo "✓ $target → $source"
}

mkdir -p "$cfg_dir/themes"
link "$here/config.ghostty" "$cfg_dir/config.ghostty"
for theme in "$here"/themes/*; do
  link "$theme" "$cfg_dir/themes/$(basename "$theme")"
done

# Per-machine settings: seeded once, never overwritten.
if [[ -e "$cfg_dir/local" ]]; then
  echo "= $cfg_dir/local (kept)"
else
  cp "$here/local.example" "$cfg_dir/local"
  echo "✓ $cfg_dir/local written (the settings of this machine)"
fi

if [[ -s "$cfg_dir/config" && ! -L "$cfg_dir/config" ]]; then
  echo "  note    : Ghostty also reads the older file $cfg_dir/config, before the shared one."
  echo "            Move the lines you want to keep to $cfg_dir/local and delete it."
fi

if problems=$(ghostty +validate-config 2>&1); then
  echo "✓ ghostty accepts the configuration"
else
  echo "✗ ghostty reports:"
  printf '%s\n' "$problems" | sed 's/^/    /'
fi

echo "  local   : $cfg_dir/local   (colour scheme, size of the letters)"
echo "  themes  : tokyo-night (default), tokyo-night-day, okabe-ito-ink, okabe-ito-paper"
echo "  reload  : Ctrl+Shift+comma in a Ghostty window"

has_font() {   # pipefail-safe: test captured output, not pipeline status
  local file needle=${1// /}
  if command -v fc-list >/dev/null; then
    [[ -n $(fc-list : family 2>/dev/null | grep -i -- "$1" | head -n1) ]] && return 0
    return 1
  fi
  for file in "$HOME/Library/Fonts"/* /Library/Fonts/*; do
    [[ ${file,,} == *"${needle,,}"* ]] && return 0
  done
  return 1
}
if ! has_font "JetBrainsMono Nerd Font"; then
  echo "  hint    : JetBrainsMono Nerd Font not found: the icons of the prompt need it (https://www.nerdfonts.com/)."
fi
if ! has_font "JuliaMono"; then
  echo "  hint    : JuliaMono not found: Greek and mathematics fall back to other fonts. Its release files are at"
  echo "            https://github.com/cormullion/juliamono/releases (unpack the .ttf files into ~/.local/share/fonts, then fc-cache -f)."
fi

# The terminal of Ctrl+Alt+T: printed, never applied (keep install non-invasive). The name of the
# desktop entry depends on the package (the archive, a snap), so it is looked up.
desktop_entry() {
  local dir f
  for dir in "${XDG_DATA_HOME:-$HOME/.local/share}/applications" /usr/local/share/applications \
             /usr/share/applications /var/lib/snapd/desktop/applications; do
    for f in "$dir"/*ghostty*.desktop; do
      if [[ -e $f ]]; then basename "$f"; return 0; fi
    done
  done
  return 1
}
if command -v xdg-terminal-exec >/dev/null && entry=$(desktop_entry); then
  list="$base/xdg-terminals.list"
  if [[ -r $list ]] && [[ $(grep -v '^[[:space:]]*#' "$list" | head -n1) == "$entry"* ]]; then
    echo "  default : Ghostty is the first terminal of $list"
  elif [[ -s $list ]]; then
    echo "  default : to make Ghostty the terminal of Ctrl+Alt+T, put this line first in $list:"
    echo "             $entry"
  else
    echo "  default : to make Ghostty the terminal of Ctrl+Alt+T, run this line yourself:"
    printf '             printf %s > "%s"\n' "'$entry\\n'" "$list"
    echo "            and to go back:  rm \"$list\""
  fi
fi
