# Contributing

Thanks for taking a look. This is a personal configuration repo that happens to be useful to other
people, so it helps to be clear about what fits upstream and what belongs in your own fork.

## What's welcome

* **Bug fixes** — a segment that renders wrongly, a crash, a wrong calculation, a broken symlink.
* **Portability** — macOS / BSD fixes, missing-tool fallbacks, older `bash`, unusual terminals.
* **Documentation** — clearer wording, missing steps, corrections.
* **Robustness in the installers** — better checks, safer backups, clearer error messages.

## What belongs in a fork

**Theme and palette preferences are not bugs.** The Okabe–Ito colours, the blue powerline, the icon
choices and the segment layout are deliberate. If you want different colours or a different layout,
fork the repo and edit `claude/statusline-command.sh` or `starship/starship.toml` — that is the
intended way to make it yours, and no one will ask you to justify it.

If you think a segment should be *optional* rather than *different*, that is a fair proposal: open an
issue suggesting a new knob in `claude/statusline.conf`.

## Trying a change before you open a PR

No installation is needed to see your edit:

```bash
# status line — render the demo payload at a given icon mode and width
bash claude/statusline-command.sh --demo                 # auto icons
bash claude/statusline-command.sh --demo nerd 120
bash claude/statusline-command.sh --demo emoji 80
bash claude/statusline-command.sh --demo unicode 90

# starship prompt — render with this repo's config, without installing it
STARSHIP_CONFIG=$PWD/starship/starship.toml starship prompt
```

To test the installers without touching your real configuration, point `HOME` somewhere disposable:

```bash
tmp=$(mktemp -d)
HOME=$tmp XDG_CONFIG_HOME=$tmp/.config bash claude/install.sh
```

## House rules the code already follows

Please keep a patch consistent with these — they are the reason the installers are safe to re-run:

1. **`set -euo pipefail`** at the top of every script.
2. **Installers are idempotent.** Running one twice must leave the machine in the same state.
3. **Never overwrite a per-machine file.** Seed it only if it is absent (`statusline.conf`).
4. **Back up before replacing** anything the user may have written, to `*.bak.<timestamp>`.
5. **Never edit a shell rc file automatically.** Print the line and let the user paste it.
6. **Quote paths** (`"$HOME/..."`) — spaces in paths must work.
7. **Degrade gracefully** when an optional tool is missing rather than failing.

## Before submitting

```bash
bash -n install.sh claude/install.sh starship/install.sh claude/statusline-command.sh
shellcheck install.sh claude/install.sh starship/install.sh   # if you have it
python3 -c "import tomllib; tomllib.load(open('starship/starship.toml','rb'))"
```

If your change touches the status line's output, please include a before/after of
`bash claude/statusline-command.sh --demo nerd 120` in the PR description.
