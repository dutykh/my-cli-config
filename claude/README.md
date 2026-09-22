# Claude Code status line

A three-line, colour-blind-safe, responsive status line for [Claude Code](https://code.claude.com).

```
  Fable 5.1 xhigh 1M   ~/workspace/CVDutykh   main ✚2 ⇡1   #42 ✓ approved   main 3.14   dutykh/CVDutykh
  ctx ━━╌╌╌╌╌╌╌╌ 18% 183k/1M │  cache ● warm 91% 52m ttl 1h │  $3.09  9m43s +86 −1 │  5h ╌╌╌╌╌ 1% ↻15:10  7d ━╌╌╌╌ 15% ↻Thu 17:00
 load 1.27/24 · mem 16% · cpu 4%  ┃  dds@spy · claude 2.1.278 ·  thinking  ┃   Claude status line  ┃  10:27:28
```

| line | what it shows |
|---|---|
| 1 identity  | model · effort level · context window size · fast-mode flag │ path │ git branch, ●staged ✚modified …untracked ✖conflicts ⇡ahead ⇣behind ⚑stash, worktree │ open PR/MR (clickable, review state) │ python venv + version, typst / rust / julia / tex / node │ remote repo |
| 2 telemetry | context gauge (input-only formula, matches Claude's own %) │ prompt-cache warm/cold, hit ratio, time to expiry │ session cost, wall time, lines ± │ 5-hour / 7-day / spend-limit gauges with reset times |
| 3 system    | load / memory / cpu since last refresh / battery ┃ user@host · Claude version · thinking / fast / vim / agent ┃ session name ┃ clock |

* **Icons** – Nerd Font glyphs when a Nerd Font is installed, emoji otherwise, plain Unicode on request.
* **Theme** – follows the Claude Code theme (`light*` / `dark*`) read from `settings.json` or `~/.claude.json`, then the terminal's `COLORFGBG` hint. Colours are the Okabe–Ito colour-blind-safe palette.
* **Responsive** – reads the `COLUMNS` Claude Code passes and drops segments on narrow terminals.
* **Fast** – one `jq` call, git status cached for a few seconds per session, `/proc` reads; ≈ 20 ms per refresh.
* **Portable** – Linux and macOS (no `/proc` → load only), GNU or BSD `stat`, optional `timeout`.

## Install on a machine

```bash
git clone <your-remote> ~/workspace/my-cli-config
~/workspace/my-cli-config/install.sh
```

The installer symlinks the script into `~/.claude/`, seeds `~/.claude/statusline.conf` if absent, and sets
`statusLine` in `~/.claude/settings.json` (a timestamped backup is kept). Update with `git pull`.

Requirements: `bash ≥ 4.3`, `jq`, `git`. Optional: a Nerd Font, selected as the terminal font.

## Configure

Edit `~/.claude/statusline.conf` (per machine, not tracked) — icon mode, theme, number of lines, which segments
to show, gauge widths, git cache time. Preview instantly:

```bash
bash ~/.claude/statusline-command.sh --demo            # auto icons
bash ~/.claude/statusline-command.sh --demo unicode 90 # icon mode + simulated width
```

## Nerd Font per terminal

* **Zed** – `settings.json`: `"terminal": { "font_family": "JetBrainsMono Nerd Font" }`
* **Warp** – Settings → Appearance → Text → Font
* **iTerm2 / Kitty / WezTerm / GNOME Terminal** – pick the Nerd Font in the profile's font setting

Until the terminal uses a Nerd Font, force `ICONS=emoji` in `statusline.conf`.
