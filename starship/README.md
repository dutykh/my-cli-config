# Starship: Tokyo Night Moon pills

A two-line [Starship](https://starship.rs) prompt: short rounded pills in the Tokyo Night Moon palette,
with Nerd Font icons, readable on **light and dark** terminal themes.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="../docs/starship-prompt-dark.png">
  <img alt="Starship prompt in Tokyo Night Moon pills: OS glyph, folder, git branch, Python version and command duration, above a chevron input line" src="../docs/starship-prompt-light.png">
</picture>

## Design

* **Pills**: each segment is a pill with its own two rounded caps, so the line ends cleanly whichever segments are present, and an absent segment leaves no gap.
* **A short first line**: the folder you are in (the repository name at its root), git, toolchains and the duration of a slow command. The user name shows only over SSH or for another user, and there is no clock.
* **Self-painted segments**: each module paints its own background and text in the Moon palette, so the bar does not depend on the terminal background; text contrast on every fill is 5.4 or more.
* **Dual-theme second line**: `❯`, errors and jobs use mid-tones with a contrast of 3.0 or more on both the Moon and the Day background.

### Palette

| token | hex | role |
|---|---|---|
| blue | `#82AAFF` | OS / user pill (text `#1E2030`) |
| bg_highlight | `#2F334D` | folder, toolchains, duration |
| blue7 | `#394B70` | git |
| fg | `#C8D3F5` | text on the folder and git pills |
| cyan | `#86E1FC` | toolchain versions |
| yellow | `#FFC777` | git status, duration, read-only lock |
| magenta | `#C099FF` | package version |
| blue0 | `#3E68D7` | ready `❯` |
| red1 | `#C53B53` | errors |
| Day magenta | `#9854F1` | jobs, vi mode |

## Prompt legend

| element | codepoint(s) | module | meaning |
|---|---|---|---|
| `` `` | `U+E0B6` `U+E0B4` | every pill | rounded caps |
| `` | `U+F31B` | `os` | OS glyph (Ubuntu shown) |
| `you` | none | `username` | current user, only over SSH or for another user |
| `@host` | none | `hostname` | only on SSH |
| ` ~` / path | `U+F015` | `directory` | cwd (`` = home); substitutions e.g. `` Downloads, `󰈙` Documents |
| `` | `U+F023` | `directory` | read-only path |
| ` branch` | `U+F418` | `git_branch` | current branch |
| `` `` `` `` `` `` `󰞇` … | `U+F055` `U+F044` `U+F128` `U+F014` `U+F062` `U+F063` `U+F0787` `U+2026` | `git_status` | staged / modified / untracked / deleted / ahead / behind / conflict |
| `` `` `` `` `` `` | `U+ED0D` `U+ED1B` `U+E7A8` `U+E627` `U+E608` `U+E624` | node / python / rust / go / php / julia | toolchain when detected |
| `` | `U+F487` | `package` | package version |
| `` | `U+F308` | `docker_context` | docker context |
| `` | `U+F313` | `nix_shell` | nix shell |
| ` 3s` | `U+F252` | `cmd_duration` | last command, when it took 2 s or more |
| ` 10:33` | `U+F017` | `time` | local time `%H:%M`, off (`disabled = false` in `[time]` brings it back) |
| `❯` | `U+276F` | `character` | ready (blue = ok, red = last command failed) |
| ` …` | `U+F00D` `U+2026` | `status` | non-zero exit detail |
| `󰫺 N` | `U+F0AFA` | `jobs` | background job count |

## Install on a machine

```bash
git clone https://github.com/dutykh/my-cli-config.git ~/workspace/my-cli-config
~/workspace/my-cli-config/install.sh
# or only this component:
~/workspace/my-cli-config/starship/install.sh
```

The installer:

1. requires `starship` on `PATH`
2. backs up an existing real `~/.config/starship.toml` (not a symlink)
3. symlinks `~/.config/starship.toml` → this repo’s `starship.toml`
4. prints the one-line shell init snippet if you still need it

Update with `git pull` (symlink keeps machines in sync).

Requirements: [Starship](https://starship.rs), a **Nerd Font** selected in the terminal
(e.g. JetBrainsMono Nerd Font, FiraCode Nerd Font, MesloLGS Nerd Font).

### Shell init (if not already present)

```bash
# bash
eval "$(starship init bash)"

# zsh
eval "$(starship init zsh)"

# fish
starship init fish | source
```

### Nerd Font per terminal

* **Warp**: Settings → Appearance → Text → Font
* **Zed**: `settings.json`: `"terminal": { "font_family": "JetBrainsMono Nerd Font" }`
* **iTerm2 / Kitty / WezTerm / GNOME Terminal**: profile font setting

## Preview without switching shell

```bash
starship prompt
STARSHIP_CONFIG=$PWD/starship/starship.toml starship prompt
```

## Files

| file | purpose |
|---|---|
| `starship.toml` | shared theme (tracked) |
| `install.sh` | symlink into `~/.config/` |

## Uninstall

```bash
rm ~/.config/starship.toml                          # the symlink
```

If the installer backed up a config you had before, restore it: `ls ~/.config/starship.toml.bak.*`.
Removing the `starship init` line from your shell rc disables the prompt entirely.

---

**Author**: Dr. Denys Dutykh, Mathematics Department, Khalifa University, Abu Dhabi, UAE ·
[Homepage](https://www.denys-dutykh.com/) · [GitHub](https://github.com/dutykh) ·
[ORCID](https://orcid.org/0000-0001-5247-2788)
**License**: [MIT](../LICENSE) · part of [my-cli-config](https://github.com/dutykh/my-cli-config)
