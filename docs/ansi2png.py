#!/usr/bin/env python3
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
"""Render ANSI-coloured terminal output to PNG using a real Nerd Font.

    ansi2png.py OUT.png [dark|light] [GHOSTTY_THEME_FILE] < output.ansi

Parses SGR sequences (truecolor fg/bg, 256-colour, bold, dim, underline, reset) and draws
each cell as a background rect + glyph, so powerline separators tile seamlessly.

Without a theme file the page is the canvas of GitHub, dark or light, and the sixteen colours
are those of a common terminal. With a Ghostty theme file, the background, the foreground and
the sixteen colours are read from it, and the picture shows that theme.

The two faces of JetBrainsMono Nerd Font Mono are found by their file names among
the fonts that fontconfig knows; ANSI2PNG_FONT and ANSI2PNG_BOLD give other files.
With a theme file, Greek and mathematics are drawn with JuliaMono when it is installed
(ANSI2PNG_MATH and ANSI2PNG_MATH_BOLD give other files), as Ghostty draws them: the blocks
that ghostty/config.ghostty sends to it, and every character that the Nerd Font lacks.
"""
import os, re, subprocess, sys
from PIL import Image, ImageDraw, ImageFont

FONT_NAME = "JetBrainsMonoNerdFontMono-Regular.ttf"
BOLD_NAME = "JetBrainsMonoNerdFontMono-Bold.ttf"
MATH_NAME = "JuliaMono-Regular.ttf"
MATH_BOLD_NAME = "JuliaMono-Bold.ttf"
GHOSTTY_CONFIG = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                              "ghostty", "config.ghostty")


def font_file(name, env, required=True):
    """Path of the font file `name`: $env when set, else the copy fontconfig lists."""
    if os.environ.get(env):
        return os.environ[env]
    try:
        listed = subprocess.run(["fc-list", "-f", "%{file}\n"], capture_output=True,
                                text=True, check=True).stdout.splitlines()
    except (OSError, subprocess.CalledProcessError):
        listed = []
    for path in sorted(listed):
        if os.path.basename(path) == name:
            return path
    if required:
        sys.exit(f"ansi2png: {name} not found; install JetBrainsMono Nerd Font or set {env}")
    return None


# fontconfig falls back to DejaVu for the few codepoints no Nerd Font variant
# carries (e.g. U+21BB ↻). Mirror that here so the image matches a real terminal.
FALLBACK = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
SIZE = 34
PAD  = 18

SGR = re.compile(r'\x1b\[([0-9;]*)m')
OSC = re.compile(r'\x1b\]8;;.*?(?:\x1b\\|\x07)')   # hyperlinks: strip, keep the label

ANSI16 = [(0,0,0),(205,49,49),(13,188,121),(229,229,16),(36,114,200),(188,63,188),
          (17,168,205),(229,229,229),(102,102,102),(241,76,76),(35,209,139),
          (245,245,67),(59,142,234),(214,112,214),(41,184,219),(255,255,255)]

def xterm256(n, ansi16=ANSI16):
    if n < 16: return ansi16[n]
    if n < 232:
        n -= 16; r,g,b = n//36, (n//6)%6, n%6
        f = lambda v: 0 if v == 0 else 55 + 40*v
        return (f(r), f(g), f(b))
    v = 8 + (n-232)*10
    return (v,v,v)

def rgb(hexa):
    return tuple(int(hexa[i:i+2], 16) for i in (1, 3, 5))

def ghostty_theme(path):
    """(foreground, background, sixteen colours) of a Ghostty theme file."""
    values, palette = {}, {}
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = (part.strip() for part in line.split("=", 1))
        if key == "palette":
            index, colour = (part.strip() for part in value.split("=", 1))
            palette[int(index)] = rgb(colour)
        else:
            values[key] = value
    return rgb(values["foreground"]), rgb(values["background"]), [palette[i] for i in range(16)]

def mapped_ranges(path=GHOSTTY_CONFIG):
    """The codepoint ranges that the Ghostty configuration sends to JuliaMono."""
    ranges = []
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        return ranges
    for line in lines:
        m = re.match(r'\s*font-codepoint-map\s*=\s*(.+?)\s*=\s*JuliaMono\s*$', line)
        if not m:
            continue
        for part in m.group(1).split(","):
            ends = [int(p.strip()[2:], 16) for p in part.split("-")]
            ranges.append((ends[0], ends[-1]))
    return ranges

class Cell:
    __slots__ = ("ch","fg","bg","bold","underline")
    def __init__(self, ch, fg, bg, bold, underline=False):
        self.ch, self.fg, self.bg, self.bold, self.underline = ch, fg, bg, bold, underline

def parse(text, default_fg, default_bg, ansi16=ANSI16):
    """ANSI string -> list of rows, each a list of Cell."""
    text = OSC.sub('', text).replace('\x1b]8;;\x07', '')
    rows, row = [], []
    fg, bg, bold, dim, underline = default_fg, None, False, False, False
    pos = 0
    for m in SGR.finditer(text):
        for ch in text[pos:m.start()]:
            if ch == '\n':
                rows.append(row); row = []
            elif ch == '\r':
                pass
            else:
                f = fg
                if dim:  # approximate dim as 65% toward the background
                    b = bg or default_bg
                    f = tuple(int(c*0.65 + bc*0.35) for c, bc in zip(f, b))
                row.append(Cell(ch, f, bg, bold, underline))
        pos = m.end()
        codes = [int(c) for c in m.group(1).split(';') if c != ''] or [0]
        i = 0
        while i < len(codes):
            c = codes[i]
            if c == 0:   fg, bg, bold, dim, underline = default_fg, None, False, False, False
            elif c == 1: bold = True
            elif c == 2: dim = True
            elif c == 4: underline = True
            elif c == 22: bold = dim = False
            elif c == 24: underline = False
            elif c == 39: fg = default_fg
            elif c == 49: bg = None
            elif 30 <= c <= 37:  fg = ansi16[c-30]
            elif 90 <= c <= 97:  fg = ansi16[c-90+8]
            elif 40 <= c <= 47:  bg = ansi16[c-40]
            elif 100 <= c <= 107: bg = ansi16[c-100+8]
            elif c in (38, 48):
                if i+1 < len(codes) and codes[i+1] == 2:
                    col = tuple(codes[i+2:i+5]); i += 4
                    if c == 38: fg = col
                    else: bg = col
                elif i+1 < len(codes) and codes[i+1] == 5:
                    col = xterm256(codes[i+2], ansi16); i += 2
                    if c == 38: fg = col
                    else: bg = col
            i += 1
    for ch in text[pos:]:
        if ch == '\n': rows.append(row); row = []
        elif ch != '\r': row.append(Cell(ch, fg, bg, bold, underline))
    if row: rows.append(row)
    while rows and not rows[0]:  rows.pop(0)
    while rows and not rows[-1]: rows.pop()
    return rows

def render(text, out, theme="dark", theme_file=None):
    ansi16 = ANSI16
    if theme_file:
        default_fg, page_bg, ansi16 = ghostty_theme(theme_file)
    elif theme == "dark":
        default_fg, page_bg = (220, 223, 228), (22, 27, 34)      # GitHub dark canvas
    else:
        default_fg, page_bg = (36, 41, 47), (255, 255, 255)      # GitHub light canvas

    rows = parse(text, default_fg, page_bg, ansi16)
    regular = font_file(FONT_NAME, "ANSI2PNG_FONT")
    font  = ImageFont.truetype(regular, SIZE)
    fontb = ImageFont.truetype(font_file(BOLD_NAME, "ANSI2PNG_BOLD"), SIZE)
    try:
        fallback = ImageFont.truetype(FALLBACK, SIZE)
        from fontTools.ttLib import TTFont as _TT
        _cm = set()
        for _t in _TT(regular)['cmap'].tables: _cm |= set(_t.cmap.keys())
    except Exception:
        fallback, _cm = None, None

    # A picture of a Ghostty theme follows the fonts of Ghostty too: JuliaMono, when it is there,
    # for the blocks that the configuration sends to it and for whatever the Nerd Font lacks.
    # It has the width of JetBrains Mono, so cells stay cells.
    math = mathb = None
    math_cm, ranges = set(), mapped_ranges()
    math_path = font_file(MATH_NAME, "ANSI2PNG_MATH", required=False) if theme_file else None
    if math_path and _cm is not None:
        math = ImageFont.truetype(math_path, SIZE)
        bold_path = font_file(MATH_BOLD_NAME, "ANSI2PNG_MATH_BOLD", required=False)
        mathb = ImageFont.truetype(bold_path, SIZE) if bold_path else math
        for _t in _TT(math_path)['cmap'].tables: math_cm |= set(_t.cmap.keys())

    def pick(cell):
        cp = ord(cell.ch)
        if math is not None and cp in math_cm:
            if any(a <= cp <= b for a, b in ranges) or cp not in _cm:
                return mathb if cell.bold else math
        if _cm is not None and cp not in _cm and fallback is not None:
            return fallback
        return fontb if cell.bold else font

    adv = font.getlength("M")
    asc, desc = font.getmetrics()
    lh = int((asc + desc) * 1.32)
    cw = adv
    width  = int(max((len(r) for r in rows), default=1) * cw) + PAD*2
    height = len(rows) * lh + PAD*2

    img = Image.new("RGB", (width, height), page_bg)
    d = ImageDraw.Draw(img)

    for y, row in enumerate(rows):
        top = PAD + y*lh
        base = top + (lh - asc - desc)/2 + asc      # one baseline for every font of the row
        # pass 1: backgrounds (drawn as exact cells so separators tile with no seam)
        for x, cell in enumerate(row):
            if cell.bg:
                d.rectangle([PAD + x*cw, top, PAD + (x+1)*cw + 0.5, top + lh], fill=cell.bg)
        # pass 2: glyphs
        for x, cell in enumerate(row):
            if cell.underline:
                d.rectangle([PAD + x*cw, base + SIZE*0.12, PAD + (x+1)*cw, base + SIZE*0.12 + max(2, SIZE//17)],
                            fill=cell.fg)
            if cell.ch == ' ': continue
            fnt = pick(cell)
            if fnt is fallback:
                # centre a fallback glyph in its cell (it may not share the mono advance)
                dx = max(0, (cw - fnt.getlength(cell.ch)) / 2)
                d.text((PAD + x*cw + dx, top + (lh - asc - desc)/2),
                       cell.ch, font=fnt, fill=cell.fg)
            else:
                d.text((PAD + x*cw, base), cell.ch, font=fnt, fill=cell.fg, anchor="ls")

    img.save(out)
    print(f"  ✓ {out}  {width}×{height}  ({len(rows)} rows × {max(len(r) for r in rows)} cols)")

if __name__ == "__main__":
    data = sys.stdin.buffer.read().decode("utf-8", "replace")
    render(data, sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "dark",
           sys.argv[3] if len(sys.argv) > 3 else None)
