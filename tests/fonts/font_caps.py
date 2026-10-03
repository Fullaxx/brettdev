#!/usr/bin/env python3
"""font_caps.py - what a font family can actually do, read straight from its font files.

For each family it reports:
  - version, styles, and whether it's a variable font;
  - embedded bitmap sizes, and whether it has an OpenType MATH table;
  - GSUB features: 'calt'/'liga', stylistic sets (ssNN), character variants (cvNN),
    'zero', ...;
  - coverage of the ranges that matter in a terminal: Powerline (U+E0A0-E0A3 and
    U+E0B0-E0B3), box drawing, block elements, Braille, Greek, Cyrillic, and the
    private-use areas where icon fonts live.

Usage:
  tests/fonts/font_caps.py [FAMILY]...    installed families (default: coding and reference fonts)
  tests/fonts/font_caps.py --dir DIR      every family under DIR, e.g. a package
                                          extracted by `debs.py fetch`

A GSUB 'calt' feature doesn't prove code ligatures. Cascadia Mono has one and
shapes none; ligatures.py checks what actually renders.
"""
import os
import struct
import subprocess
import sys

DEFAULT = ["DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono", "Anonymous Pro", "Cascadia Code",
           "Cascadia Mono", "Cascadia Code PL", "Fira Code", "Go Mono", "Hack", "JetBrains Mono",
           "mononoki", "Ubuntu Mono", "Ubuntu Sans Mono", "Symbols Nerd Font Mono", "Noto Color Emoji",
           "Noto Sans Math", "STIX Math"]
FMT = "%{file}|%{index}|%{family}|%{style[0]}|%{variable}|%{fontversion}|%{charset}\n"
RANGES = [("powerline(8)", [(0xE0A0, 0xE0A3), (0xE0B0, 0xE0B3)]), ("box(128)", [(0x2500, 0x257F)]),
          ("blocks(32)", [(0x2580, 0x259F)]), ("braille(256)", [(0x2800, 0x28FF)]),
          ("greek", [(0x370, 0x3FF)]), ("cyrillic", [(0x400, 0x4FF)]), ("PUA", [(0xE000, 0xF8FF)]),
          ("plane15-PUA", [(0xF0000, 0xFFFFD)])]


def charset(text):
    out = set()
    for tok in text.split():
        a, _, b = tok.partition("-")
        out.update(range(int(a, 16), int(b or a, 16) + 1))
    return out


def sfnt_tables(path, index):
    data = open(path, "rb").read()
    off = 0
    if data[:4] == b"ttcf":
        off = struct.unpack(">I", data[12 + 4 * index:16 + 4 * index])[0]
    n = struct.unpack(">H", data[off + 4:off + 6])[0]
    tables = {}
    for i in range(n):
        rec = data[off + 12 + 16 * i:off + 28 + 16 * i]
        tables[rec[:4].decode("latin1")] = struct.unpack(">II", rec[8:16])
    return data, tables


def gsub_features(data, tables):
    if "GSUB" not in tables:
        return []
    o = tables["GSUB"][0]
    fl = o + struct.unpack(">H", data[o + 6:o + 8])[0]
    n = struct.unpack(">H", data[fl:fl + 2])[0]
    return sorted({data[fl + 2 + 6 * i:fl + 6 + 6 * i].decode("latin1") for i in range(n)})


def bitmap_sizes(data, tables):
    if "EBLC" not in tables:
        return []
    o = tables["EBLC"][0]
    n = struct.unpack(">I", data[o + 4:o + 8])[0]
    return sorted({data[o + 8 + 48 * i + 45] for i in range(n)})  # ppemY of each strike


def rows_for(args):
    if args[:1] == ["--dir"]:
        files = [os.path.join(r, f) for r, _, fs in os.walk(args[1]) for f in fs
                 if f.lower().endswith((".ttf", ".otf", ".ttc"))]
        out = "".join(subprocess.run(["fc-scan", "--format", FMT, f], capture_output=True, text=True).stdout
                      for f in sorted(files))
        wanted = None
    else:
        out = subprocess.run(["fc-list", "--format", FMT], capture_output=True, text=True).stdout
        wanted = args or DEFAULT
    groups = {}
    for line in out.splitlines():
        parts = line.split("|", 6)
        if len(parts) < 7:
            continue
        names = [n.strip() for n in parts[2].split(",")]
        key = names[0] if wanted is None else next((w for w in wanted if w in names), None)
        if key:
            groups.setdefault(key, []).append(parts)
    return groups, wanted


def main():
    if sys.argv[1:2] in (["-h"], ["--help"]):
        print(__doc__)
        return
    groups, wanted = rows_for(sys.argv[1:])
    for fam in (wanted or sorted(groups)):
        rows = groups.get(fam)
        if not rows:
            print(f"## {fam}: not installed\n")
            continue
        styles = sorted({r[3] for r in rows if r[3]})
        cs = set().union(*(charset(r[6]) for r in rows))
        rep = next((r for r in rows if r[3] in ("Regular", "Book", "Roman")), rows[0])
        data, tables = sfnt_tables(rep[0], int(rep[1] or 0))
        feats = gsub_features(data, tables)
        ss = [f for f in feats if f.startswith("ss")]
        cv = [f for f in feats if f.startswith("cv")]
        other = [f for f in feats if f not in ss and f not in cv]
        flags = [t.strip() for t in ("fvar", "MATH", "EBDT", "CBDT", "COLR", "sbix", "CFF ") if t in tables]
        print(f"## {fam}  v{int(rep[5]) / 65536:.3f}  ({len({r[0] for r in rows})} files)")
        print(f"   styles: {', '.join(styles)}")
        print(f"   tables: {' '.join(flags) or '-'}"
              + (f"   embedded bitmaps at {bitmap_sizes(data, tables)} px" if "EBLC" in tables else ""))
        print(f"   GSUB: {' '.join(other) or '-'}   stylistic sets: {len(ss)} {' '.join(ss)}"
              f"   character variants: {len(cv)}")
        cov = "  ".join(f"{label}={sum(1 for a, b in spans for c in range(a, b + 1) if c in cs)}"
                        for label, spans in RANGES)
        print(f"   codepoints={len(cs)}  {cov}\n")


if __name__ == "__main__":
    main()
