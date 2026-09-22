# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 0.1.0 — 2026-09-22

Initial public release.

### Added

* **`claude/`** — a three-line Claude Code status line: identity (model, effort, context window,
  path, git status, open PR, toolchain, remote), telemetry (context gauge, prompt-cache warmth,
  session cost and wall time, 5-hour / 7-day / spend rate limits) and system (load, memory, cpu,
  battery, host, version, session, clock). Nerd Font / emoji / Unicode icon modes, light-dark
  aware, Okabe–Ito colour-blind-safe palette, responsive to terminal width.
* **`starship/`** — a two-line blue powerline Starship prompt with self-painted segments that stay
  readable on both light and dark terminal themes.
* **Symlink-based installers** — a root `install.sh` that runs every component, plus a per-component
  installer. Per-machine settings are seeded once and never overwritten; replaced files are backed
  up with a timestamp; shell rc files are never edited automatically.
* Project documentation: `README.md`, per-component READMEs, `CONTRIBUTING.md` and an MIT `LICENSE`.
