# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

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
