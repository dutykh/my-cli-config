#!/usr/bin/env python3
"""Render ANSI-coloured terminal output to PNG using a real Nerd Font.

Parses SGR sequences (truecolor fg/bg, 256-colour, bold, dim, reset) and draws
each cell as a background rect + glyph, so powerline separators tile seamlessly.
"""
import re, sys
from PIL import Image, ImageDraw, ImageFont

FONT = "/home/dds/.local/share/fonts/JetBrainsMonoNerdFontMono-Regular.ttf"
BOLD = "/home/dds/.local/share/fonts/JetBrainsMonoNerdFontMono-Bold.ttf"
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

def xterm256(n):
    if n < 16: return ANSI16[n]
    if n < 232:
        n -= 16; r,g,b = n//36, (n//6)%6, n%6
        f = lambda v: 0 if v == 0 else 55 + 40*v
        return (f(r), f(g), f(b))
    v = 8 + (n-232)*10
    return (v,v,v)

class Cell:
    __slots__ = ("ch","fg","bg","bold")
    def __init__(self, ch, fg, bg, bold):
        self.ch, self.fg, self.bg, self.bold = ch, fg, bg, bold

def parse(text, default_fg, default_bg):
    """ANSI string -> list of rows, each a list of Cell."""
    text = OSC.sub('', text).replace('\x1b]8;;\x07', '')
    rows, row = [], []
    fg, bg, bold, dim = default_fg, None, False, False
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
                row.append(Cell(ch, f, bg, bold))
        pos = m.end()
        codes = [int(c) for c in m.group(1).split(';') if c != ''] or [0]
        i = 0
        while i < len(codes):
            c = codes[i]
            if c == 0:   fg, bg, bold, dim = default_fg, None, False, False
            elif c == 1: bold = True
            elif c == 2: dim = True
            elif c == 22: bold = dim = False
            elif c == 39: fg = default_fg
            elif c == 49: bg = None
            elif 30 <= c <= 37:  fg = ANSI16[c-30]
            elif 90 <= c <= 97:  fg = ANSI16[c-90+8]
            elif 40 <= c <= 47:  bg = ANSI16[c-40]
            elif 100 <= c <= 107: bg = ANSI16[c-100+8]
            elif c in (38, 48):
                if i+1 < len(codes) and codes[i+1] == 2:
                    col = tuple(codes[i+2:i+5]); i += 4
                    if c == 38: fg = col
                    else: bg = col
                elif i+1 < len(codes) and codes[i+1] == 5:
                    col = xterm256(codes[i+2]); i += 2
                    if c == 38: fg = col
                    else: bg = col
            i += 1
    for ch in text[pos:]:
        if ch == '\n': rows.append(row); row = []
        elif ch != '\r': row.append(Cell(ch, fg, bg, bold))
    if row: rows.append(row)
    while rows and not rows[0]:  rows.pop(0)
    while rows and not rows[-1]: rows.pop()
    return rows

def render(text, out, theme="dark"):
    if theme == "dark":
        default_fg, page_bg = (220, 223, 228), (22, 27, 34)      # GitHub dark canvas
    else:
        default_fg, page_bg = (36, 41, 47), (255, 255, 255)      # GitHub light canvas

    rows = parse(text, default_fg, page_bg)
    font  = ImageFont.truetype(FONT, SIZE)
    fontb = ImageFont.truetype(BOLD, SIZE)
    try:
        fallback = ImageFont.truetype(FALLBACK, SIZE)
        from fontTools.ttLib import TTFont as _TT
        _cm = set()
        for _t in _TT(FONT)['cmap'].tables: _cm |= set(_t.cmap.keys())
    except Exception:
        fallback, _cm = None, None

    def pick(cell):
        if _cm is not None and ord(cell.ch) not in _cm and fallback is not None:
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
        # pass 1: backgrounds (drawn as exact cells so separators tile with no seam)
        for x, cell in enumerate(row):
            if cell.bg:
                d.rectangle([PAD + x*cw, top, PAD + (x+1)*cw + 0.5, top + lh], fill=cell.bg)
        # pass 2: glyphs
        for x, cell in enumerate(row):
            if cell.ch == ' ': continue
            fnt = pick(cell)
            # centre a fallback glyph in its cell (it may not share the mono advance)
            dx = 0
            if fnt is fallback:
                dx = max(0, (cw - fnt.getlength(cell.ch)) / 2)
            d.text((PAD + x*cw + dx, top + (lh - asc - desc)/2),
                   cell.ch, font=fnt, fill=cell.fg)

    img.save(out)
    print(f"  ✓ {out}  {width}×{height}  ({len(rows)} rows × {max(len(r) for r in rows)} cols)")

if __name__ == "__main__":
    data = sys.stdin.buffer.read().decode("utf-8", "replace")
    render(data, sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "dark")
