#!/usr/bin/env bash
# Install / update the Starship blue powerline theme on this machine.
#   git clone <your-remote> ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
# Re-running is safe. Updating later is just `git pull` (the config is symlinked, not copied).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cfg_dir=${XDG_CONFIG_HOME:-$HOME/.config}
mkdir -p "$cfg_dir"
target="$cfg_dir/starship.toml"
source_toml="$here/starship.toml"

command -v starship >/dev/null || {
  echo "✗ starship is required"
  echo "  install:  curl -sS https://starship.rs/install.sh | sh"
  echo "         or brew install starship"
  exit 1
}

# Back up a real file once; never clobber an existing backup chain blindly.
if [[ -e $target && ! -L $target ]]; then
  bak="$target.bak.$(date +%Y%m%d-%H%M%S)"
  cp -a "$target" "$bak"
  echo "• backed up existing config → $bak"
fi

ln -sfn "$source_toml" "$target"
echo "✓ starship theme installed → $target (symlink to $source_toml)"

# Shell init hints (do not auto-edit rc files — keep install non-invasive).
shell_name=$(basename "${SHELL:-bash}")
case $shell_name in
  bash) init_line='eval "$(starship init bash)"' ;;
  zsh)  init_line='eval "$(starship init zsh)"' ;;
  fish) init_line='starship init fish | source' ;;
  *)    init_line='eval "$(starship init bash)"' ;;
esac
echo "  enable  : add this to your shell rc if Starship is not already active:"
echo "             $init_line"
echo "  preview : starship prompt"

has_nerd_font() {
  command -v fc-list >/dev/null && [[ -n $(fc-list 2>/dev/null | grep -i nerd | head -n1) ]] && return 0
  [[ -n $(ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -i nerd | head -n1) ]] && return 0
  [[ -n $(find "$HOME/.local/share/fonts" "$HOME/.fonts" /usr/local/share/fonts /usr/share/fonts -maxdepth 3 -iname '*nerd*' -print -quit 2>/dev/null) ]] && return 0
  return 1
}
if ! has_nerd_font; then
  echo "  hint    : no Nerd Font found — install one (e.g. JetBrainsMono Nerd Font) and select it in your terminal."
fi
