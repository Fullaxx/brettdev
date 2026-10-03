#!/usr/bin/env python3
"""glyph_coverage.py - which symbols can a program print that no installed font can draw?

Scans a binary (default: the `claude` executable) for symbol codepoints: UTF-8
literals and JS escapes in U+2000-U+2BFF and U+1F000-U+1FAFF. Checks them against
the installed fonts through fontconfig, so it also works under fcconf.sh.

With --candidates DIR (a directory of extracted .debs, see `debs.py fetch`), it also
reports how many missing codepoints each candidate package would fix.

The binary-wide count is noisy: emoji tables and regexes bundled into the program
count too. So the HEADLINE list, the glyphs Claude Code's UI actually draws, gets
its own table.

Usage:
  tests/fonts/glyph_coverage.py [--binary PATH] [--candidates DIR] [--combo PKG+PKG]...

Found on 2026-10-03 (brettdev-full before add_fonts.sh):
  - ⎿ ⏵ ⏸ ⏺ ⏹ ⎯ ⧉ and every emoji had no font.
  - fonts-noto-core fixes the symbols; fonts-noto-color-emoji fixes the emoji.
  - None of the coding fonts fixes any of them (Anonymous Pro 0, Hack 1 of the
    binary-wide set). fonts-symbola or fonts-unifont alone would have worked too.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import unicodedata

WORK = os.environ.get("FONTTEST_WORK") or os.path.join(os.environ.get("TMPDIR", "/tmp"), "fonttest")

HEADLINE = [
    (0x23BF, "tool-result connector"), (0x23F5, "accept-edits mode"), (0x23F8, "plan mode"),
    (0x23FA, "record / tool bullet"), (0x23F9, "stop"), (0x23AF, "divider"),
    (0x29C9, "IDE selection marker"), (0x25CF, "bullet"), (0x276F, "prompt"),
    (0x273B, "spinner"), (0x273D, "spinner"), (0x2736, "spinner"), (0x2733, "spinner"),
    (0x2722, "spinner"), (0x2026, "ellipsis"), (0x00B7, "middle dot"), (0x2610, "todo"),
    (0x2612, "todo done"), (0x2714, "check"), (0x2718, "cross"), (0x26A0, "warning"),
    (0x2705, "emoji"), (0x274C, "emoji"), (0x2728, "emoji"), (0x1F916, "emoji"), (0x1F680, "emoji"),
]


def parse_charset(text):
    out = set()
    for tok in text.split():
        a, _, b = tok.partition("-")
        out.update(range(int(a, 16), int(b or a, 16) + 1))
    return out


def coverage(env=None):
    """{family: charset} for every font fontconfig can see."""
    res = subprocess.run(["fc-list", "--format", "%{family[0]}|%{charset}\n"],
                         capture_output=True, text=True, env=env)
    fams = {}
    for line in res.stdout.splitlines():
        fam, _, cs = line.partition("|")
        fams.setdefault(fam, set()).update(parse_charset(cs))
    return fams


def private_env(name, fontdir):
    """Environment whose fontconfig sees only fontdir (cache kept in the work dir)."""
    confdir = os.path.join(WORK, "fcconf")
    os.makedirs(confdir, exist_ok=True)
    os.makedirs(os.path.join(WORK, "fccache"), exist_ok=True)
    conf = os.path.join(confdir, f"cand-{name}.conf")
    with open(conf, "w") as f:
        f.write('<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">\n'
                f'<fontconfig><cachedir>{WORK}/fccache</cachedir><dir>{fontdir}</dir></fontconfig>\n')
    env = dict(os.environ, FONTCONFIG_FILE=conf)
    env.pop("FONTCONFIG_PATH", None)
    return env


def scan(path):
    data = open(path, "rb").read()
    found = set()
    for m in re.finditer(rb"\xe2[\x80-\xaf][\x80-\xbf]|\xf0\x9f[\x80-\xab][\x80-\xbf]", data):
        try:
            found.add(ord(m.group().decode()))
        except UnicodeDecodeError:
            pass
    for m in re.finditer(rb"\\u(2[0-9A-Ba-b][0-9A-Fa-f]{2})", data):
        found.add(int(m.group(1), 16))
    for m in re.finditer(rb"\\u\{(1F[0-9A-Fa-f]{3})\}", data):
        found.add(int(m.group(1), 16))
    for m in re.finditer(rb"\\u(D83[CDE])\\u(D[C-F][0-9A-Fa-f]{2})", data, re.I):
        hi, lo = int(m.group(1), 16), int(m.group(2), 16)
        found.add(0x10000 + ((hi - 0xD800) << 10) + (lo - 0xDC00))
    return found


def name(cp):
    try:
        return unicodedata.name(chr(cp)).title()
    except ValueError:
        return "?"


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--binary", help="file to scan (default: the claude executable)")
    ap.add_argument("--candidates", help="dir of extracted packages, one subdir per package")
    ap.add_argument("--combo", action="append", default=[], help="PKG+PKG to score together")
    args = ap.parse_args()

    binary = args.binary or (shutil.which("claude") and os.path.realpath(shutil.which("claude")))
    if not binary:
        sys.exit("no --binary given and `claude` is not on PATH")

    fams = coverage()
    installed = set().union(*fams.values()) if fams else set()
    cands = {}
    if args.candidates:
        for pkg in sorted(os.listdir(args.candidates)):
            d = os.path.join(args.candidates, pkg)
            if os.path.isdir(d):
                cands[pkg] = set().union(*coverage(private_env(pkg, d)).values() or [set()])

    print("== Claude Code UI glyphs (installed fonts) ==")
    for cp, what in HEADLINE:
        who = sorted(f for f, cs in fams.items() if cp in cs)
        print(f"  U+{cp:04X} {chr(cp)}  {what:22} {', '.join(who[:2]) or '*** NO FONT ***'}")

    if cands:
        short = {p: p.replace("fonts-", "")[:10] for p in cands}
        print("\n== which candidate package covers each UI glyph (Y) ==")
        print(" " * 11 + "".join(f"{short[p]:>11}" for p in cands))
        for cp, _ in HEADLINE:  # the glyph goes last: emoji are double-width and would skew the columns
            print(f"  U+{cp:05X}  " + "".join(f"{'Y' if cp in cands[p] else '.':>11}" for p in cands)
                  + f"   {chr(cp)}")

    used = scan(binary)
    missing = sorted(cp for cp in used if cp not in installed)
    print(f"\n== {binary}: {len(used)} symbol codepoints referenced, {len(missing)} with no installed font ==")
    print("   (binary-wide counts include bundled emoji tables, so treat them as an upper bound)")
    if missing:
        print("   e.g. " + " ".join(chr(c) for c in missing[:40]))
    if cands and missing:
        print("\n== how many of those each candidate would fix ==")
        for p, cs in cands.items():
            print(f"  {p:26} {sum(1 for c in missing if c in cs):5}/{len(missing)}")
        for combo in args.combo:
            pkgs = combo.split("+")
            u = set().union(*(cands.get(p, set()) for p in pkgs))
            left = [c for c in missing if c not in u]
            print(f"  {combo:50} {len(missing) - len(left):5}/{len(missing)}  still missing: "
                  + "".join(chr(c) for c in left[:30]))


if __name__ == "__main__":
    main()
