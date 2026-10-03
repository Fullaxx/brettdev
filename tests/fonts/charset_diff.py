#!/usr/bin/env python3
"""charset_diff.py - which codepoints of font family A are missing from family B?

Usage:
  tests/fonts/charset_diff.py FAMILY_A FAMILY_B [--range START-END] [--show N]
    --range  only compare codepoints in this hex range (default: all of A's)
    --show   list up to N missing codepoints (default 40)

Families come from fontconfig, so to compare a font that isn't installed,
extract it first and add its dir:
  tests/fonts/debs.py fetch fonts-font-awesome
  tests/fonts/fcconf.sh "$FONTTEST_WORK/fonts/fonts-font-awesome" -- \
      tests/fonts/charset_diff.py FontAwesome "Symbols Nerd Font" --range E000-F8FF

Found on 2026-10-03: all 694 FontAwesome (4.7) icons, U+F000-U+F500, are in
Symbols Nerd Font v3.5.1 at the same codepoints. So fonts-font-awesome adds nothing.
"""
import argparse
import subprocess
import sys


def charset(family):
    out = subprocess.run(["fc-list", family, "--format", "%{charset}\n"], capture_output=True, text=True).stdout
    cs = set()
    for line in out.splitlines():
        for tok in line.split():
            a, _, b = tok.partition("-")
            cs.update(range(int(a, 16), int(b or a, 16) + 1))
    return cs


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("a")
    ap.add_argument("b")
    ap.add_argument("--range")
    ap.add_argument("--show", type=int, default=40)
    args = ap.parse_args()
    a, b = charset(args.a), charset(args.b)
    for fam, cs in ((args.a, a), (args.b, b)):
        if not cs:
            sys.exit(f"{fam}: no such family (check `fc-list : family`)")
    if args.range:
        lo, _, hi = args.range.partition("-")
        a = {c for c in a if int(lo, 16) <= c <= int(hi or lo, 16)}
    missing = sorted(a - b)
    print(f"{args.a}: {len(a)} codepoints compared"
          + (f" (U+{min(a):04X}-U+{max(a):04X})" if a else ""))
    print(f"missing from {args.b}: {len(missing)}")
    if missing:
        print("  " + " ".join(f"U+{c:04X}" for c in missing[:args.show]))


if __name__ == "__main__":
    main()
