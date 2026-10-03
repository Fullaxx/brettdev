#!/usr/bin/env python3
"""debs.py - inspect Ubuntu packages straight from the archive, without installing them.

Subcommands:
  index [--refresh]           download the Packages indexes (cached for a day in $WORK/idx)
  show [--grep RE] [--installed] PKG...
                              version, size, component and Depends/Recommends/Suggests
                              (--grep keeps only relation entries matching RE, e.g. 'font';
                              --installed reads the installed package via dpkg instead, for
                              packages from outside the archive like google-chrome-stable or
                              the Mozilla PPA's firefox)
  rdeps PKG                   archive packages that Depend / Pre-Depend / Recommend PKG
  fetch PKG...                download each .deb and extract it into $WORK/fonts/PKG
  cat PKG MEMBER              print one file from a .deb, read in memory
                              (e.g. ./etc/fonts/conf.avail/65-droid-sans-fallback.conf)

Environment:
  FONTTEST_WORK   work dir (default ${TMPDIR:-/tmp}/fonttest)
  DIST            release (default noble); DIST-updates is searched before DIST
  MIRROR          default http://archive.ubuntu.com/ubuntu
  ARCH            default amd64
  COMPONENTS      default "main universe"

Nothing here installs packages or touches dpkg state. Examples from 2026-10-03:
  debs.py show --grep font libreoffice     the 11 font packages LibreOffice recommends
  debs.py rdeps fonts-font-awesome         67 packages, almost all web apps and docs
  debs.py rdeps fonts-droid-fallback       includes libgs10-common (Recommends)
  debs.py cat fonts-droid-fallback ./etc/fonts/conf.avail/65-droid-sans-fallback.conf
"""
import lzma
import os
import re
import subprocess
import sys
import time
import urllib.request

WORK = os.environ.get("FONTTEST_WORK") or os.path.join(os.environ.get("TMPDIR", "/tmp"), "fonttest")
DIST = os.environ.get("DIST", "noble")
MIRROR = os.environ.get("MIRROR", "http://archive.ubuntu.com/ubuntu").rstrip("/")
ARCH = os.environ.get("ARCH", "amd64")
COMPONENTS = os.environ.get("COMPONENTS", "main universe").split()
RELATIONS = ("Pre-Depends", "Depends", "Recommends", "Suggests")
FONT_EXT = (".ttf", ".otf", ".ttc", ".pcf.gz", ".otb")


def index_files(refresh=False):
    idx = os.path.join(WORK, "idx")
    os.makedirs(idx, exist_ok=True)
    paths = []
    for pocket in (f"{DIST}-updates", DIST):
        for comp in COMPONENTS:
            path = os.path.join(idx, f"{pocket}_{comp}_{ARCH}.Packages")
            stale = not os.path.exists(path) or time.time() - os.path.getmtime(path) > 86400
            if refresh or stale:
                url = f"{MIRROR}/dists/{pocket}/{comp}/binary-{ARCH}/Packages.xz"
                print(f"fetching {url}", file=sys.stderr)
                with urllib.request.urlopen(url, timeout=600) as r:
                    data = lzma.decompress(r.read())
                with open(path, "wb") as f:
                    f.write(data)
            paths.append(path)
    return paths


def records():
    """Yield one dict per package stanza; the -updates pocket comes first."""
    for path in index_files():
        with open(path, encoding="utf-8", errors="replace") as f:
            for stanza in f.read().split("\n\n"):
                rec, key = {}, None
                for line in stanza.splitlines():
                    if line[:1] in (" ", "\t") and key:
                        rec[key] += "\n" + line
                    elif ":" in line:
                        key, _, val = line.partition(":")
                        rec[key] = val.strip()
                if "Package" in rec:
                    yield rec


_latest = None


def lookup(pkg):
    global _latest
    if _latest is None:
        _latest = {}
        for rec in records():
            _latest.setdefault(rec["Package"], rec)  # first hit is the newest pocket
    rec = _latest.get(pkg)
    if rec is None:
        sys.exit(f"{pkg}: not found in {DIST}/{DIST}-updates ({' '.join(COMPONENTS)})")
    return rec


def relation_names(value):
    """'a (>= 1) | b, c:any' -> ['a', 'b', 'c']"""
    names = []
    for group in value.split(","):
        for alt in group.split("|"):
            name = re.split(r"[\s(:\[]", alt.strip(), maxsplit=1)[0]
            if name:
                names.append(name)
    return names


def installed_version(pkg):
    res = subprocess.run(["dpkg-query", "-W", "-f=${Status}|${Version}", pkg], capture_output=True, text=True)
    status, _, version = res.stdout.partition("|")
    return version if "ok installed" in status else None


def deb_bytes(pkg):
    rec = lookup(pkg)
    debdir = os.path.join(WORK, "debs")
    os.makedirs(debdir, exist_ok=True)
    path = os.path.join(debdir, os.path.basename(rec["Filename"]))
    if not os.path.exists(path):
        url = f"{MIRROR}/{rec['Filename']}"
        print(f"fetching {url}", file=sys.stderr)
        with urllib.request.urlopen(url, timeout=600) as r, open(path + ".part", "wb") as f:
            f.write(r.read())
        os.rename(path + ".part", path)
    return path


def installed_record(pkg):
    fields = ["Version", "Installed-Size"] + list(RELATIONS)
    fmt = "\\n".join(f"{f}: ${{{f}}}" for f in fields)
    res = subprocess.run(["dpkg-query", "-W", f"-f={fmt}", pkg], capture_output=True, text=True)
    if res.returncode or not installed_version(pkg):
        sys.exit(f"{pkg}: not installed")
    rec = {}
    for line in res.stdout.splitlines():
        key, _, val = line.partition(": ")
        if val:
            rec[key] = val
    rec["Filename"] = "dpkg/installed"
    return rec


def cmd_show(args):
    pattern, from_dpkg = None, False
    while args[:1] in (["--grep"], ["--installed"]):
        if args[0] == "--grep":
            pattern, args = re.compile(args[1]), args[2:]
        else:
            from_dpkg, args = True, args[1:]
    for pkg in args:
        rec = installed_record(pkg) if from_dpkg else lookup(pkg)
        comp = rec["Filename"].split("/")[1]
        have = installed_version(pkg)
        print(f"{pkg} {rec['Version']}  {rec.get('Installed-Size', '?')} KB installed  ({comp})"
              f"  [{'installed ' + have if have else 'not installed'}]")
        for rel in RELATIONS:
            if rel not in rec:
                continue
            entries = [e.strip() for e in rec[rel].replace("\n", " ").split(",")]
            if pattern:
                entries = [e for e in entries if pattern.search(e)]
            if entries:
                print(f"  {rel}: {', '.join(entries)}")


def cmd_rdeps(args):
    target = args[0]
    hits = {}
    for rec in records():
        for rel in ("Pre-Depends", "Depends", "Recommends"):
            if target in relation_names(rec.get(rel, "")):
                hits.setdefault(rec["Package"], set()).add(rel)
    for pkg in sorted(hits):
        have = installed_version(pkg)
        print(f"  {pkg:45} {'/'.join(sorted(hits[pkg])):22} {'INSTALLED' if have else ''}")
    print(f"{len(hits)} packages depend on or recommend {target}")


def cmd_fetch(args):
    for pkg in args:
        deb = deb_bytes(pkg)
        dest = os.path.join(WORK, "fonts", pkg)
        os.makedirs(dest, exist_ok=True)
        subprocess.run(["dpkg-deb", "-x", deb, dest], check=True)
        fonts = [os.path.join(r, f) for r, _, fs in os.walk(dest) for f in fs if f.endswith(FONT_EXT)]
        print(f"{pkg}: {len(fonts)} font files in {dest}")


def cmd_cat(args):
    pkg, member = args
    if not member.startswith("./"):
        member = "./" + member.lstrip("/")
    with open(deb_bytes(pkg), "rb") as f:
        data = f.read()
    if data[:8] != b"!<arch>\n":
        sys.exit("not a .deb")
    off = 8
    while off < len(data):
        name = data[off:off + 16].decode().strip().rstrip("/")
        size = int(data[off + 48:off + 58])
        body = data[off + 60:off + 60 + size]
        off += 60 + size + (size & 1)
        if name.startswith("data.tar"):
            decomp = {"data.tar.zst": ["zstd", "-dc"], "data.tar.xz": ["xz", "-dc"],
                      "data.tar.gz": ["gzip", "-dc"], "data.tar": ["cat"]}[name]
            tarball = subprocess.run(decomp, input=body, capture_output=True, check=True).stdout
            res = subprocess.run(["tar", "-xOf", "-", member], input=tarball, capture_output=True)
            if res.returncode:
                sys.exit(res.stderr.decode().strip() or f"{member} not in {pkg}")
            sys.stdout.buffer.write(res.stdout)
            return
    sys.exit("no data.tar member in the .deb")


def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__)
        return
    cmd, args = sys.argv[1], sys.argv[2:]
    if cmd == "index":
        index_files(refresh="--refresh" in args)
    elif cmd == "show" and args:
        cmd_show(args)
    elif cmd == "rdeps" and len(args) == 1:
        cmd_rdeps(args)
    elif cmd == "fetch" and args:
        cmd_fetch(args)
    elif cmd == "cat" and len(args) == 2:
        cmd_cat(args)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
