#!/usr/bin/python3
"""vte_render.py - render a sample of Claude Code's UI the way terminator draws it.

Draws into an offscreen Vte.Terminal (the widget terminator uses), with the font
set fontconfig currently sees, and saves a PNG. Run it under fcconf.sh to compare
font sets without installing anything. For example, the "before" picture in
docs/fonts/claude-glyphs.png (DejaVu and Liberation only):

  tests/fonts/fcconf.sh --no-system /usr/share/fonts/truetype/dejavu -- \
      tests/fonts/vte_render.py --label "DejaVu only" --out /tmp/before.png

Usage: tests/fonts/vte_render.py [--font "DejaVu Sans Mono 12"] [--label TEXT] [--cols 72] --out FILE.png
Needs the system python (/usr/bin/python3) with GTK 3 and VTE 2.91, plus a DISPLAY.

Found on 2026-10-03: with the image's original fonts, every ⎿ ⏸ ⏵ ⏺ ⏹ ⧉ ⎯ and
emoji was a hex box. fonts-noto-core fixed the symbols, and
fonts-noto-color-emoji fixed the emoji.
"""
import argparse
import sys

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo
import vtecap  # noqa: E402
from vtecap import Gtk

E = "\x1b["
SAMPLE = [
    f"{E}90m❯{E}0m /plan",
    "  ⎿  Enabled plan mode",
    f"{E}32m●{E}0m {E}1mBash{E}0m(ls -la)",
    "  ⎿  Allowed by auto mode classifier",
    f"{E}31m✽{E}0m {E}33mElucidating…{E}0m (31s · ↓ 2.9k tokens)",
    f"  {E}36m⏸ plan mode on{E}0m (shift+tab to cycle)   {E}35m⏵⏵ accept edits on{E}0m",
    "  ⏺ Update(app.py)   ⏹ stop   ⧉ In app.py   ⎯⎯⎯⎯⎯⎯",
    "  spinner: ✻ ✽ ✶ ✳ ✢   todo: ☐ ☒ ✔ ✘   ⚠ warn  ◐ ◑",
    "  emoji: ✅ done  ❌ fail  ✨ new  🤖 bot  🚀 ship",
]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--font", default="DejaVu Sans Mono 12")
    ap.add_argument("--label", default="")
    ap.add_argument("--cols", type=int, default=72)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    head = f"{E}1;33m{args.label}{E}0m" + (f"  ({args.font})" if args.label else args.font)
    term = vtecap.terminal(args.font, "\n".join([head] + SAMPLE), args.cols)
    win = Gtk.OffscreenWindow()
    win.add(term)
    win.show_all()
    vtecap.size_terminals([term])
    pb = vtecap.capture(win, ready=lambda p: vtecap.drawn(p, [term], minimum=40))
    if pb is None:
        sys.exit("timed out waiting for VTE to draw (is DISPLAY set?)")
    vtecap.save(pb, args.out)


if __name__ == "__main__":
    main()
