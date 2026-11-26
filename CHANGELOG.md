# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Added

* **`ghostty/themes/tokyo-night-moon`**: the Moon variant of Tokyo Night, now the default theme of
  Ghostty, as on the desktop and in the prompt. Its colours are those of the Moon terminal theme of
  Tokyo Night (the one that Ghostty ships as `TokyoNight Moon`), with colour 8 set to the Moon comment
  colour `#636DA6`: dim text keeps a contrast of 3.1 on the background `#222436`, where the shipped
  `#444A73` gives 1.8. The Storm theme `tokyo-night` stays, one line of the file `local` away.

### Changed

* The file `ghostty/config.ghostty` chooses `tokyo-night-moon`, and `docs/palette.py` measures it
  beside Tokyo Night and its Day companion: text 10.3, colour 8 3.1, selected text 6.8, cursor 10.3.
  The pictures of `docs/` show the Moon theme.
* **`ghostty/`**: a new window has 96 columns and 20 rows, in place of 78 by 20. On a desktop that
  scales its text by 1.25 the plain request gives 77 by 14, and `fit-window.sh --write 96 20` measures
  the request of the local file: 120 by 27 at `font-size = 10.5`. The width 95 was tried first and
  left, because at that size of the letters the grid goes from 94 columns to 96.
* **`tmux/`**: the session pill of the status line wears the Moon blue `#82AAFF` with the dark text
  `#1E2030`, like the first pill of the prompt.

* **`starship/`**: the prompt is shorter and wears Tokyo Night Moon. Each segment is a pill with its
  own rounded caps, so the line ends cleanly whichever segments are present. The folder shows only its
  own name (the repository name at its root), the user name appears only over SSH or for another user,
  and the clock is off. Text contrast on every pill is 5.4 or more, and the marks of the second line
  keep 3.0 on both the Moon and the Day background.
* `docs/ansi2png.py` draws the powerline arrows and the rounded caps as shapes that fill the cell, as
  terminals do, so the pictures show no step between a cap and its segment. `docs/make-previews.sh`
  renders the prompt with the real login, so the pictures show no user name, as on a local machine.

## 0.2.0 (2026-11-24)

The terminal itself joins the prompt and the status line.

### Added

* **`ghostty/`**: a configuration for the terminal Ghostty. The colours are Tokyo Night, with its
  dim colour 8 made readable (a contrast of 3.0 in place of 1.6), a light companion, and a house pair
  on the hues of Okabe and Ito as the alternative; one line of a per-machine file chooses among the
  four. JetBrains Mono draws the text and JuliaMono, of the same width, Greek and mathematics. The
  tabs sit in the title bar, the split without the keyboard is veiled, the bell is silent, a long
  command reports when it ends, and the keys leave Alt+digit, Ctrl+Enter and every Ctrl+letter to the
  programs. The README gives the reason of each line.
* **`tmux/`**: a configuration for tmux that passes full colour, links, the clipboard and modified
  keys through to the terminal, and draws a quiet status line in the colours of the terminal.
* **`docs/palette.py`**: measures the terminal themes: the contrast of each text colour on the
  background, and the distance between the hues for normal vision, protanopia and deuteranopia. The
  house pair passes every rule, and the values of Tokyo Night are printed beside it.
* **`docs/terminal-demo.sh`**, with two more previews, `terminal-dark.png` and `terminal-light.png`:
  a short made-up session (prompt, listing, the sixteen colours, mathematics, Cyrillic, French) in
  the colours of the theme.

### Changed

* `docs/ansi2png.py` reads the colours of a Ghostty theme file, draws underlines, and uses JuliaMono
  for mathematics in the terminal previews. The four earlier pictures come out pixel for pixel as
  before.
* `docs/make-previews.sh` regenerates the previews named on its command line, or all of them.
* The installers of the two new components skip a machine that lacks the program, change nothing on a
  second run, and never choose the default terminal: the line that does it is printed.

## 0.1.0 (2026-09-22)

Initial public release.

### Added

* **`claude/`**: a three-line Claude Code status line: identity (model, effort, context window,
  path, git status, open PR, toolchain, remote), telemetry (context gauge, prompt-cache warmth,
  session cost and wall time, 5-hour / 7-day / spend rate limits) and system (load, memory, cpu,
  battery, host, version, session, clock). Nerd Font / emoji / Unicode icon modes, light-dark
  aware, Okabe–Ito colour-blind-safe palette, responsive to terminal width.
* **`starship/`**: a two-line blue powerline Starship prompt with self-painted segments that stay
  readable on both light and dark terminal themes.
* **Symlink-based installers**: a root `install.sh` that runs every component, plus a per-component
  installer. Per-machine settings are seeded once and never overwritten; replaced files are backed
  up with a timestamp; shell rc files are never edited automatically.
* Project documentation: `README.md`, per-component READMEs, `CONTRIBUTING.md` and an MIT `LICENSE`.

### Changed before the tag of 2026-11-15

The version was published on 22 September 2026 and tagged on 15 November 2026; in between:

* The previews are pictures of the real output drawn with the real font (`docs/`), since GitHub draws
  the Nerd Font glyphs of a code block as empty boxes.
* The README explains how the Claude component sits beside a private configuration.
* The previews show a neutral user on a neutral machine, `you@laptop`, and the demo of the status line
  shows the clone at `~/workspace/my-cli-config`, with its git status, and this repository, instead
  of a folder of the author's machine.
* The renderer `docs/ansi2png.py` finds JetBrainsMono Nerd Font Mono through fontconfig instead of a
  fixed path; `ANSI2PNG_FONT` and `ANSI2PNG_BOLD` name other files.
* A citation file, `CITATION.cff`, lets GitHub show how to cite the repository, and the Markdown
  files lose their em-dashes and flat inequality signs.
