#!/usr/bin/env python3
# Author : Dr. Denys Dutykh (Mathematics Department, Khalifa University of Science and Technology, Abu Dhabi, UAE)
# License: MIT, see LICENSE at the repository root
"""Measure the colours of a terminal theme: is every text colour readable, and do the hues stay
apart for a colour-blind reader?

    docs/palette.py                 the four themes of ghostty/themes
    docs/palette.py FILE ...        other Ghostty theme files, by the same rules
    docs/palette.py --markdown      the same tables as Markdown, for a README

The rules: the foreground and the fourteen text colours (1 to 7 and 9 to 15) reach a contrast of
4.5 on the background, the dim colour 8 reaches 3, the selection reaches 4.5, the cursor reaches 3,
and the six hues (red, green, yellow, blue, magenta, cyan) keep a distance of at least 5, in their
normal and in their bright set, for normal vision, protanopia and deuteranopia. The contrast is the
ratio of WCAG 2. The distance is the Euclidean one of OKLab, times 100, after the colours are seen
through the dichromacy matrices of Machado, Oliveira and Fernandes (2009) in linear sRGB.

The house pair (okabe-ito-ink, okabe-ito-paper) is built to pass every rule, and the exit status is
1 when one of its values falls below its floor. The Tokyo Night pair keeps the hues of its scheme:
it is measured by the same rules, its low values are marked, and they do not change the exit status.
A file named on the command line is judged like the house pair. Standard library only.
"""
import argparse
import re
import sys
from itertools import combinations
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
HOUSE = ["okabe-ito-ink", "okabe-ito-paper"]        # judged: these must pass
MEASURED = ["tokyo-night", "tokyo-night-day"]       # measured: the hues of their scheme stay
NAMES = ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white"]
HUES = range(1, 7)

TEXT_FLOOR = 4.5        # the foreground and every text colour, on the background
DIM_FLOOR = 3.0         # colour 8, the dim text
SELECTION_FLOOR = 4.5   # selected text on the selection
CURSOR_FLOOR = 3.0      # the cursor against the background
HUE_FLOOR = 5.0         # smallest distance between two hues, OKLab times 100

# Machado, Oliveira and Fernandes (2009), severity 1, applied to linear sRGB.
VISION = {
    "normal": None,
    "protanopia": ((0.152286, 1.052583, -0.204868),
                   (0.114503, 0.786281, 0.099216),
                   (-0.003882, -0.048116, 1.051998)),
    "deuteranopia": ((0.367322, 0.860646, -0.227968),
                     (0.280085, 0.672501, 0.047413),
                     (-0.011820, 0.042940, 0.968881)),
    "tritanopia": ((1.255528, -0.076749, -0.178779),
                   (-0.078411, 0.930809, 0.147602),
                   (0.004733, 0.691367, 0.303900)),
}
JUDGED = ("normal", "protanopia", "deuteranopia")


def linear(hexa):
    """'#RRGGBB' as three linear sRGB values between 0 and 1."""
    out = []
    for i in (1, 3, 5):
        c = int(hexa[i:i + 2], 16) / 255
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return tuple(out)


def luminance(hexa):
    r, g, b = linear(hexa)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(one, other):
    """The contrast ratio of WCAG 2 between two colours, from 1 to 21."""
    hi, lo = sorted((luminance(one), luminance(other)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def seen(rgb, vision):
    """A linear colour as a dichromat sees it, kept inside the gamut."""
    matrix = VISION[vision]
    if matrix is None:
        return rgb
    return tuple(min(1.0, max(0.0, sum(m * c for m, c in zip(row, rgb)))) for row in matrix)


def oklab(rgb):
    r, g, b = rgb
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def distance(one, other, vision):
    """Distance between two colours in OKLab, times 100, for the given vision."""
    a, b = (oklab(seen(linear(c), vision)) for c in (one, other))
    return 100 * sum((x - y) ** 2 for x, y in zip(a, b)) ** 0.5


def read_theme(path):
    """A Ghostty theme file as {'background': ..., 'palette': {0: ..., 15: ...}, ...}."""
    theme = {"name": Path(path).name, "palette": {}}
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = (part.strip() for part in line.split("=", 1))
        if key == "palette":
            index, colour = (part.strip() for part in value.split("=", 1))
            theme["palette"][int(index)] = colour.upper()
        else:
            theme[key] = value.upper() if re.fullmatch(r"#[0-9A-Fa-f]{6}", value) else value
    missing = [k for k in ("background", "foreground") if k not in theme]
    missing += [f"palette {i}" for i in range(16) if i not in theme["palette"]]
    if missing:
        sys.exit(f"palette: {path} lacks {', '.join(missing)}")
    return theme


def closest(theme, indices, vision):
    """The two hues of `indices` that are nearest for this vision: (distance, i, j)."""
    return min((distance(theme["palette"][i], theme["palette"][j], vision), i, j)
               for i, j in combinations(indices, 2))


def measure(theme):
    """Every rule applied to one theme: rows of (label, colours, value, floor)."""
    ground, palette = theme["background"], theme["palette"]
    rows = [("foreground", theme["foreground"], contrast(theme["foreground"], ground), TEXT_FLOOR)]
    for i in range(16):
        kind = "bright " if i > 7 else ""
        label = f"{i:2d} {kind}{NAMES[i % 8]}"
        if i == 0:
            rows.append((label + ", a surface", palette[i], contrast(palette[i], ground), None))
        elif i == 8:
            rows.append((label + ", dim text", palette[i], contrast(palette[i], ground), DIM_FLOOR))
        else:
            rows.append((label, palette[i], contrast(palette[i], ground), TEXT_FLOOR))
    rows.append(("text on a row of colour 8", f"{theme['foreground']} on {palette[8]}",
                 contrast(theme["foreground"], palette[8]), None))
    if "selection-background" in theme:
        front = theme.get("selection-foreground", theme["foreground"])
        rows.append(("selected text", f"{front} on {theme['selection-background']}",
                     contrast(front, theme["selection-background"]), SELECTION_FLOOR))
    if "cursor-color" in theme:
        rows.append(("cursor", theme["cursor-color"], contrast(theme["cursor-color"], ground), CURSOR_FLOOR))
    hues = []
    for label, indices in (("hues 1 to 6", HUES), ("bright hues 9 to 14", [i + 8 for i in HUES])):
        for vision in VISION:
            d, i, j = closest(theme, indices, vision)
            pair = f"{NAMES[i % 8]} and {NAMES[j % 8]}"
            hues.append((label, vision, d, pair, HUE_FLOOR if vision in JUDGED else None))
    return rows, hues


def report(theme, markdown, judged):
    """Print the tables of one theme and return the number of its values below their floor."""
    rows, hues = measure(theme)
    low = "LOW" if judged else "low"
    mark = lambda value, floor: "" if floor is None else ("ok" if value >= floor else low)
    below = sum(1 for *_, value, floor in rows if floor is not None and value < floor)
    below += sum(1 for _, _, d, _, floor in hues if floor is not None and d < floor)
    title = f"{theme['name']} (background {theme['background']})"
    if markdown:
        print(f"**{title}**\n")
        print("| colour | value | contrast on the background | floor |")
        print("|---|---|---|---|")
        for label, colours, value, floor in rows:
            print(f"| {label.strip()} | `{colours}` | {value:.1f} | {'' if floor is None else floor} |")
        print("\n| smallest distance between two hues | normal | protanopia | deuteranopia | tritanopia |")
        print("|---|---|---|---|---|")
        for label in dict.fromkeys(h[0] for h in hues):
            cells = [f"{d:.1f} ({pair})" for name, _, d, pair, _ in hues if name == label]
            print(f"| {label} | " + " | ".join(cells) + " |")
        print()
    else:
        print(title)
        for label, colours, value, floor in rows:
            limit = "" if floor is None else f"floor {floor}"
            print(f"  {label:27s} {colours:20s} {value:5.1f}   {limit:10s} {mark(value, floor)}")
        for label, vision, d, pair, floor in hues:
            limit = "" if floor is None else f"floor {floor}"
            print(f"  {label + ', ' + vision:48s} {d:5.1f}   {limit:10s} {mark(d, floor):3s} {pair}")
        print()
    return below


def main():
    parser = argparse.ArgumentParser(description="Measure the colours of a terminal theme.")
    parser.add_argument("themes", nargs="*", help="Ghostty theme files (default: those of ghostty/themes)")
    parser.add_argument("--markdown", action="store_true", help="print the tables as Markdown")
    args = parser.parse_args()

    failures = 0
    if args.themes:
        for path in args.themes:
            failures += report(read_theme(path), args.markdown, judged=True)
    else:
        folder = REPO / "ghostty" / "themes"
        for name in HOUSE:
            failures += report(read_theme(folder / name), args.markdown, judged=True)
        noted = sum(report(read_theme(folder / name), args.markdown, judged=False) for name in MEASURED)
        if not args.markdown:
            print(f"palette: {noted} value{'s' * (noted != 1)} of the Tokyo Night pair below a floor "
                  f"(marked low, kept as the scheme has them)")
    if failures and not args.markdown:
        print(f"palette: {failures} finding{'s' * (failures != 1)}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
