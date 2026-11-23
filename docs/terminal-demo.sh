#!/usr/bin/env bash
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
#
# Print a short made-up terminal session, to see what a colour theme and a pair of fonts do:
# the Starship prompt, a coloured listing of a small project, the sixteen colours of the
# terminal with their names, and lines of mathematics, Cyrillic and French.
#
#   ghostty -e docs/terminal-demo.sh --wait     in a window of its own, until a key is pressed
#   docs/terminal-demo.sh 70 > session.ansi     70 columns wide, for docs/ansi2png.py
#
# The project lives in a temporary folder, removed at the end. Its git status is real, so the
# prompt and the listing show what they show in a repository. The session degrades gracefully:
# without starship the prompt is a plain chevron, without eza the listing is that of ls.
# With --wait, the file named by TERMINAL_DEMO_READY is created once everything is printed.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

wait_for_key=0
cols=""
for arg in "$@"; do
  case $arg in
    --wait) wait_for_key=1 ;;
    *[!0-9]*|"") echo "usage: terminal-demo.sh [--wait] [COLUMNS]" >&2; exit 2 ;;
    *) cols=$arg ;;
  esac
done
if [[ -z $cols ]]; then
  cols=$( { [[ -t 1 ]] && tput cols 2>/dev/null; } || echo "${COLUMNS:-80}")
fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
project="$tmp/kdv-solitons"
mkdir -p "$project/figures" "$project/src"
cd "$project"

printf '# Solitons of the Korteweg–de Vries equation\n' > README.md
printf 'import numpy as np\n' > kdv.py
printf 'from kdv import step\n' > src/solver.py
printf '= Two solitons\n' > paper.typ
printf 'python3 kdv.py\n' > run.sh
printf 'PNG\n' > figures/soliton.png
cp figures/soliton.png soliton.png
printf 'results\n' > results.tar.gz
ln -s figures/soliton.png latest
cat > notes.txt <<'NOTES'
KdV:  ∂ₜu + 6u ∂ₓu + ∂ₓ³u = 0,  x ∈ ℝ,  ‖u(t)‖ = ‖u₀‖ in L²(ℝ)
ϑ ϱ ϵ ∂ ∇ ∫ ∑ ⩽ ⩾ ‖u‖ ℝ → ⇒ ≈   α β γ λ μ π ω   𝒪(ε²)
Чуєш їх, доцю, га? Кумедна ж ти, прощайся без ґольфів!
Voix ambiguë d’un cœur qui, au zéphyr, préfère les jattes de kiwis.
NOTES
# Whether two characters join into a ligature is the work of the terminal: this line is for a
# real window only.
if [[ -t 1 ]]; then
  printf '%s\n' 'Typed pairs: -> => != <= >=   and   0O 1lI   {} [] ()' >> notes.txt
fi
cat > colours.sh <<'COLOURS'
#!/usr/bin/env bash
# The sixteen colours of the terminal: a swatch, the number and the name, a word in the colour.
names=(black red green yellow blue magenta cyan white)
for i in 0 1 2 3 4 5 6 7; do
  for j in $i $((i + 8)); do
    name=${names[i]}; ((j > 7)) && name="bright $name"
    printf '\e[48;5;%dm    \e[0m %2d %-14s \e[38;5;%dmtext\e[0m      ' "$j" "$j" "$name" "$j"
  done
  printf '\n'
done
COLOURS
chmod +x run.sh colours.sh

if command -v git >/dev/null; then
  git init -q -b main . 2>/dev/null || git init -q .
  git add README.md kdv.py paper.typ run.sh src figures 2>/dev/null || true
fi

prompt() {
  if command -v starship >/dev/null; then
    env -u STARSHIP_SHELL STARSHIP_CONFIG="${STARSHIP_CONFIG:-$repo/starship/starship.toml}" \
      starship prompt --status 0 --terminal-width "$cols" 2>/dev/null
  else
    printf '\n\e[1;34m❯\e[0m '
  fi
}
typed() { printf '%s\n' "$1"; }

# In a window of its own, the title names the project and not this script.
[[ -t 1 ]] && printf '\e]2;%s\a' 'kdv-solitons'

prompt
if command -v eza >/dev/null; then
  typed "eza -l --icons --git --no-user"
  eza -l --icons=always --git --no-user --color=always . < /dev/null
else
  typed "ls -l"
  ls -l --color=always . 2>/dev/null || ls -l .
fi
prompt; typed "./colours.sh"; ./colours.sh
prompt; typed "cat notes.txt"; cat notes.txt
prompt

if ((wait_for_key)); then
  [[ -n ${TERMINAL_DEMO_READY:-} ]] && : > "$TERMINAL_DEMO_READY"
  read -r -s -n 1 _ || true
fi
printf '\n'
