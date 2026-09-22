#!/usr/bin/env bash
# Install / update the Claude Code status line on this machine.
#   git clone <your-remote> ~/workspace/my-cli-config && ~/workspace/my-cli-config/install.sh
# Re-running is safe. Updating later is just `git pull` (the script is symlinked, not copied).
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cdir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
mkdir -p "$cdir"

command -v jq  >/dev/null || { echo "✗ jq is required   (apt install jq  |  brew install jq)"; exit 1; }
command -v git >/dev/null || { echo "✗ git is required"; exit 1; }

ln -sfn "$here/statusline-command.sh" "$cdir/statusline-command.sh"
chmod +x "$here/statusline-command.sh"
[[ -e "$cdir/statusline.conf" ]] || cp "$here/statusline.conf" "$cdir/statusline.conf"   # per-machine knobs, never overwritten

settings="$cdir/settings.json"
[[ -s $settings ]] || echo '{}' > "$settings"
cp "$settings" "$settings.bak.$(date +%Y%m%d-%H%M%S)"
jq --arg cmd "bash \"$cdir/statusline-command.sh\"" \
   '.statusLine = ((.statusLine // {}) + {type:"command", command:$cmd, refreshInterval:2, hideVimModeIndicator:true})' \
   "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"

echo "✓ status line installed → $cdir/statusline-command.sh (symlink to $here)"
echo "  knobs   : $cdir/statusline.conf"
echo "  preview : bash $cdir/statusline-command.sh --demo [nerd|emoji|unicode] [COLUMNS]"
has_nerd_font() {   # pipefail-safe: test captured output, not pipeline status
  command -v fc-list >/dev/null && [[ -n $(fc-list 2>/dev/null | grep -i nerd | head -n1) ]] && return 0
  [[ -n $(ls "$HOME/Library/Fonts" /Library/Fonts 2>/dev/null | grep -i nerd | head -n1) ]] && return 0
  [[ -n $(find "$HOME/.local/share/fonts" "$HOME/.fonts" /usr/local/share/fonts /usr/share/fonts -maxdepth 3 -iname '*nerd*' -print -quit 2>/dev/null) ]] && return 0
  return 1
}
if ! has_nerd_font; then
  echo "  hint    : no Nerd Font found — icons fall back to emoji. Install one (e.g. JetBrainsMono Nerd Font) and select it in your terminal."
fi
