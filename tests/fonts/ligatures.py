#!/usr/bin/python3
"""ligatures.py - which fonts actually turn code sequences into ligatures?

Renders each token twice with Pango, the text engine GTK apps use: once with the
default OpenType features, and once with liga/calt/clig/dlig switched off. If the
pixels differ, the font substituted something for that token. This is more
reliable than looking for a 'calt' feature: Cascadia Mono has one and shapes no
code ligatures.

Usage:
  tests/fonts/ligatures.py [FAMILY]...                  default: the coding fonts
  tests/fonts/ligatures.py --tokens "-> =>" "Fira Code"

Found on 2026-10-03:
  - Fira Code 17/17, Cascadia Code 17/17, JetBrains Mono 16/17 (no `www`).
  - Every other installed coding font: 0.
  - VTE terminals such as terminator show no ligatures regardless (see `specimen.py
    ligatures`). GTK editors and VS Code (with editor.fontLigatures) do.

Needs the system python (/usr/bin/python3) with PyGObject, Pango and pycairo.
"""
import argparse
import subprocess

import gi

gi.require_version("Pango", "1.0")
gi.require_version("PangoCairo", "1.0")
import cairo  # noqa: E402
from gi.repository import Pango, PangoCairo  # noqa: E402

TOKENS = "-> => != === !== <= >= :: |> <> /* */ www && || ++ ..."
FAMILIES = ["DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono", "Anonymous Pro", "Cascadia Code",
            "Cascadia Mono", "Fira Code", "Go Mono", "Hack", "JetBrains Mono", "mononoki", "Ubuntu Mono",
            "Ubuntu Sans Mono"]


def pixels(family, text, features_off):
    surface = cairo.ImageSurface(cairo.FORMAT_A8, 240, 40)
    cr = cairo.Context(surface)
    layout = PangoCairo.create_layout(cr)
    layout.set_font_description(Pango.FontDescription(f"{family} 14"))
    layout.set_text(text, -1)
    if features_off:
        attrs = Pango.AttrList()
        attrs.insert(Pango.attr_font_features_new("liga 0, calt 0, clig 0, dlig 0"))
        layout.set_attributes(attrs)
    PangoCairo.show_layout(cr, layout)
    surface.flush()
    return bytes(surface.get_data())


def installed(family):
    return bool(subprocess.run(["fc-list", family, "family"], capture_output=True, text=True).stdout.strip())


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("families", nargs="*")
    ap.add_argument("--tokens", default=TOKENS)
    args = ap.parse_args()
    tokens = args.tokens.split()
    for fam in args.families or FAMILIES:
        if not installed(fam):
            print(f"{fam:18} not installed")
            continue
        hits = [t for t in tokens if pixels(fam, t, False) != pixels(fam, t, True)]
        verdict = f"{len(hits)}/{len(tokens)}  {' '.join(hits)}" if hits else f"0/{len(tokens)}"
        print(f"{fam:18} ligatures/contextual alternates: {verdict}")


if __name__ == "__main__":
    main()
