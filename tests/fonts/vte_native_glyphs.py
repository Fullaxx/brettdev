#!/usr/bin/python3
"""vte_native_glyphs.py - does VTE draw a character itself, or does it need a font?

Renders a control character ('A'), then each given codepoint in an offscreen
Vte.Terminal, and prints each cell as ASCII art with a few numbers.
  - A hex box (VTE's "no font has this" placeholder) is a rectangle outline with
    tiny digits inside: many separate blobs.
  - A glyph VTE draws itself fills the cell in its own way, e.g. a solid arrow
    or lines that reach the cell edges.
Run it under a font set that lacks the codepoints, so only VTE could draw them:

  tests/fonts/debs.py fetch fonts-anonymous-pro
  tests/fonts/fcconf.sh --no-system "$FONTTEST_WORK/fonts/fonts-anonymous-pro" -- \
      tests/fonts/vte_native_glyphs.py --font "Anonymous Pro 20" e0a0 e0b0 e0b2 e702

Usage: tests/fonts/vte_native_glyphs.py [--font "FAMILY SIZE"] HEX...
Needs the system python (/usr/bin/python3) with GTK 3 and VTE 2.91, plus a DISPLAY.

Found on 2026-10-03 (VTE 0.76): the Powerline codepoints U+E0A0/E0B0/E0B2 came out
as hex boxes, just like the devicon control U+E702. So VTE does not draw Powerline
glyphs itself; they show up only when a font has them. The offscreen capture can
be flaky: if the control 'A' never appears, the script gives up rather than
reporting empty cells.
"""
import argparse
import sys

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo
import vtecap  # noqa: E402
from vtecap import Gtk


def blobs(grid):
    h, w = len(grid), len(grid[0])
    seen, count = set(), 0
    for y in range(h):
        for x in range(w):
            if grid[y][x] and (y, x) not in seen:
                count += 1
                stack = [(y, x)]
                seen.add((y, x))
                while stack:
                    cy, cx = stack.pop()
                    for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                        if 0 <= ny < h and 0 <= nx < w and grid[ny][nx] and (ny, nx) not in seen:
                            seen.add((ny, nx))
                            stack.append((ny, nx))
    return count


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--font", default="Monospace 20")
    ap.add_argument("codepoints", nargs="+", help="hex codepoints, e.g. e0b0 2588")
    args = ap.parse_args()
    cells = ["A"] + [chr(int(c, 16)) for c in args.codepoints]
    labels = ["A (control)"] + [f"U+{c.upper()}" for c in args.codepoints]

    # every character is followed by a space: hex boxes can spill into the next cell
    term = vtecap.terminal(args.font, "".join(c + " " for c in cells), len(cells) * 2, fg="#ffffff")
    win = Gtk.OffscreenWindow()
    win.add(term)
    win.show_all()
    vtecap.size_terminals([term])
    cw, ch = term.get_char_width(), term.get_char_height()
    pb = vtecap.capture(win, ready=lambda p: vtecap.bright_pixels(p, 0, 0, cw, min(ch, p.get_height())) > 5)
    if pb is None:
        sys.exit("the control 'A' was never drawn; the offscreen capture failed, so no verdict")

    px, rs, nc = pb.get_pixels(), pb.get_rowstride(), pb.get_n_channels()
    height = min(ch, pb.get_height())
    print(f"font {args.font}: cell {cw}x{ch}px; each slice is the glyph's cell plus the next one")
    for i, label in enumerate(labels):
        x0 = i * 2 * cw
        grid = [[px[y * rs + (x0 + x) * nc] > 110 for x in range(2 * cw)] for y in range(height)]
        lit = sum(map(sum, grid)) / (2 * cw * height)
        print(f"--- {label}: lit {lit:.1%}, {blobs(grid)} blobs ---")
        for row in grid[::2]:
            print("   " + "".join("#" if v else "." for v in row))


if __name__ == "__main__":
    main()
