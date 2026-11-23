#!/usr/bin/env bash
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
#
# Install / update the tmux configuration on this machine.
#   git clone https://github.com/dutykh/my-cli-config.git ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
# Re-running is safe: a second run changes nothing. Updating later is just `git pull`
# (the configuration is symlinked, not copied).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg_dir=${XDG_CONFIG_HOME:-$HOME/.config}/tmux
target="$cfg_dir/tmux.conf"
source_conf="$here/tmux.conf"

command -v tmux >/dev/null || {
  echo "• tmux is not installed: nothing linked"
  echo "  install:  sudo apt install tmux   |   brew install tmux, then run this installer again"
  exit 0
}

if [[ -L $target && $(readlink "$target") == "$source_conf" ]]; then
  echo "= $target"
else
  if [[ -d $target && ! -L $target ]]; then
    echo "✗ $target is a folder: left alone"
    exit 1
  fi
  mkdir -p "$cfg_dir"
  # Back up a real file once; a link or an empty file holds nothing to keep.
  if [[ -s $target && ! -L $target ]]; then
    bak="$target.bak.$(date +%Y%m%d-%H%M%S)"
    cp -a "$target" "$bak"
    echo "• backed up existing config → $bak"
  fi
  ln -sfn "$source_conf" "$target"
  echo "✓ tmux configuration installed → $target (symlink to $source_conf)"
fi

if [[ -e $HOME/.tmux.conf ]]; then
  echo "  note    : tmux also reads $HOME/.tmux.conf, before this file: where both set an option, this file wins."
fi
echo "  reload  : tmux source-file $target     (a server that already runs keeps its settings until then)"
echo "  version : $(tmux -V), made for tmux 3.5 or later"
