# Preview images

The images in this folder are what `README.md`, `claude/README.md` and `starship/README.md`
show as previews. Each exists in a `-light` and a `-dark` variant; the READMEs select between
them with a `<picture>` element, so GitHub serves the one matching the reader's theme.

## Why images and not code blocks

Both themes draw their icons and powerline separators from the Nerd Font **private use area**
(`U+E000`–`U+F8FF`). GitHub renders README text in its own web font, which has no glyphs there,
so a pasted code block shows a row of empty boxes instead of the prompt. Rendering the real ANSI
output to PNG with the actual font is the only way to show what the terminal shows.

One glyph, `U+21BB ↻` (the rate-limit reset arrow), is absent from *every* JetBrainsMono Nerd
Font variant. Terminals get it through fontconfig fallback, so `ansi2png.py` mirrors that with a
DejaVu Sans fallback and the image matches reality.

## Regenerating

```bash
docs/make-previews.sh
```

Run it after changing `starship/starship.toml` or the status line's appearance, and commit the
updated PNGs. It needs `python3` with Pillow and fontTools, a Nerd Font, `starship` and `jq`;
`optipng` is used to shrink the output if present.

The pictures are public, so they show a neutral user on a neutral machine, `you@laptop`, whoever
runs the script: both components run with a temporary home that holds a clean clone at
`~/workspace/my-cli-config` (the folder that the status line's demo shows) and a throwaway Python
environment named `demo`, without SSH variables, and the user name of the prompt goes through an
alias of Starship's `username` module. The font, JetBrainsMono Nerd Font Mono, is found through
fontconfig by the names of its files; the variables `ANSI2PNG_FONT` and `ANSI2PNG_BOLD` point
`ansi2png.py` at other files.

| file | what it renders |
|---|---|
| `ansi2png.py` | ANSI (truecolor / 256-colour / bold / dim) → PNG, drawing each cell so powerline separators tile without seams |
| `make-previews.sh` | drives the two components at both themes and writes the four PNGs |
