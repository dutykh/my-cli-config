# Contributing

Thanks for taking a look. This is a personal configuration repo that happens to be useful to other
people, so it helps to be clear about what fits upstream and what belongs in your own fork.

## What's welcome

* **Bug fixes**: a segment that renders wrongly, a crash, a wrong calculation, a broken symlink.
* **Portability**: macOS / BSD fixes, missing-tool fallbacks, older `bash`, unusual terminals.
* **Documentation**: clearer wording, missing steps, corrections.
* **Robustness in the installers**: better checks, safer backups, clearer error messages.

## What belongs in a fork

**Theme and palette preferences are not bugs.** The Okabe–Ito colours, the blue powerline, the icon
choices, the segment layout, and the colours, fonts and keys of the terminal are deliberate. If you
want different colours or a different layout, fork the repo and edit `claude/statusline-command.sh`,
`starship/starship.toml` or `ghostty/config.ghostty`; that is the intended way to make it yours, and
no one will ask you to justify it. A colour of a terminal theme that cannot be read is a bug, though:
`docs/palette.py` measures it.

If you think a segment should be *optional* rather than *different*, that is a fair proposal: open an
issue suggesting a new knob in `claude/statusline.conf`.

## Trying a change before you open a PR

No installation is needed to see your edit:

```bash
# status line: render the demo payload at a given icon mode and width
bash claude/statusline-command.sh --demo                 # auto icons
bash claude/statusline-command.sh --demo nerd 120
bash claude/statusline-command.sh --demo emoji 80
bash claude/statusline-command.sh --demo unicode 90

# starship prompt: render with this repo's config, without installing it
STARSHIP_CONFIG=$PWD/starship/starship.toml starship prompt
```

To test the installers without touching your real configuration, point `HOME` somewhere disposable:

```bash
tmp=$(mktemp -d)
HOME=$tmp XDG_CONFIG_HOME=$tmp/.config bash claude/install.sh
HOME=$tmp XDG_CONFIG_HOME=$tmp/.config bash ghostty/install.sh   # links, then asks ghostty to validate
HOME=$tmp XDG_CONFIG_HOME=$tmp/.config bash tmux/install.sh
```

The terminal has its own trial runs:

```bash
# the look of a theme in a real window, without installing anything
ghostty --config-file=ghostty/themes/okabe-ito-ink -e docs/terminal-demo.sh --wait

# the contrast of every colour of the four themes, and the distance between their hues
python3 docs/palette.py
```

## House rules the code already follows

Please keep a patch consistent with these: they are the reason the installers are safe to re-run:

1. **`set -euo pipefail`** at the top of every script.
2. **Installers are idempotent.** Running one twice must leave the machine in the same state.
3. **Never overwrite a per-machine file.** Seed it only if it is absent (`statusline.conf`).
4. **Back up before replacing** anything the user may have written, to `*.bak.<timestamp>`.
5. **Never edit a shell rc file automatically.** Print the line and let the user paste it.
6. **Quote paths** (`"$HOME/..."`), so that spaces in paths work.
7. **Degrade gracefully** when an optional tool is missing rather than failing. An installer whose
   program is absent says so and ends with status 0, so that the others still run.
8. **Never choose for the desktop.** The default terminal is the user's: print the line that sets it.

## Before submitting

```bash
bash -n install.sh claude/install.sh starship/install.sh ghostty/install.sh tmux/install.sh \
        claude/statusline-command.sh docs/make-previews.sh docs/terminal-demo.sh
shellcheck install.sh claude/install.sh starship/install.sh ghostty/install.sh tmux/install.sh   # if you have it
python3 -c "import tomllib; tomllib.load(open('starship/starship.toml','rb'))"
python3 docs/palette.py                         # the house themes must pass every rule
ghostty +validate-config                        # after ghostty/install.sh, if you have Ghostty
```

If your change touches the status line's output, please include a before/after of
`bash claude/statusline-command.sh --demo nerd 120` in the PR description.
