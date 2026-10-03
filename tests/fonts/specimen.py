#!/usr/bin/python3
"""specimen.py - font specimen sheets, rendered the way the desktop draws them.

Modes:
  fonts      every coding font in an offscreen Vte.Terminal (what terminator shows):
             confusable characters, operators, a code line, bold, Powerline glyphs,
             and a few fallback glyphs
  ligatures  Fira Code, Cascadia Code and JetBrains Mono, as VTE draws them versus
             GTK/Pango text. VTE never shows ligatures.
  icons      Powerline and Nerd Font icon codepoints under a few primary fonts.
             Run it under `fcconf.sh --reject '/usr/local/share/fonts/nerd-fonts-symbols/*'`
             to see the "before" state.
  stack      stack PNGs vertically:  specimen.py stack --out OUT.png IN1.png IN2.png ...
  zoom       crop and enlarge:       specimen.py zoom --out OUT.png --crop X,Y,W,H --scale 4 IN.png

Usage: tests/fonts/specimen.py MODE --out FILE.png [--title TEXT] [--size 10] [--fonts "A,B,C"]
Needs the system python (/usr/bin/python3) with GTK 3 and VTE 2.91, plus a DISPLAY.
make_doc_images.sh uses this to produce docs/fonts/*.png.
"""
import argparse
import subprocess
import sys

sys.dont_write_bytecode = True  # keep __pycache__ out of the repo
import vtecap  # noqa: E402
from vtecap import GdkPixbuf, GLib, Gtk

E = "\x1b["
CODING = ["DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono", "Anonymous Pro", "Cascadia Code",
          "Cascadia Mono", "Fira Code", "Go Mono", "Hack", "JetBrains Mono", "mononoki", "Ubuntu Mono",
          "Ubuntu Sans Mono"]
LIGATURE_FONTS = ["Fira Code", "Cascadia Code", "JetBrains Mono"]
ICON_FONTS = ["DejaVu Sans Mono", "Hack", "JetBrains Mono"]
POWERLINE = " "
ICONS = "      \U000f0219 "
ICON_NAMES = "git-branch  git  folder  codicon  seti-folder  ubuntu  md-icon  github"
LIG_TEXT = "-> => != === !== <= >= :: |> <> /* */ www && ||"


def installed(family):
    return bool(subprocess.run(["fc-list", family, "family"], capture_output=True, text=True).stdout.strip())


def heading(box, text, size=11):
    label = Gtk.Label(xalign=0)
    label.set_markup(f"<span font='Liberation Sans Bold {size}' foreground='#fabd2f'>"
                     f"{GLib.markup_escape_text(text)}</span>")
    box.pack_start(label, False, False, 2)


def gtk_label(box, family, size, text):
    label = Gtk.Label(xalign=0)
    label.set_markup(f"<span font='{family} {size + 1}'>{GLib.markup_escape_text(text)}</span>")
    box.pack_start(label, False, False, 0)


def render(build, out):
    vtecap.style_page()
    win = Gtk.OffscreenWindow()
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
    box.set_border_width(6)
    win.add(box)
    terms = build(box)
    win.show_all()
    vtecap.size_terminals(terms)
    pb = vtecap.capture(win, ready=lambda p: vtecap.drawn(p, terms))
    if pb is None:
        sys.exit("timed out waiting for VTE to draw (is DISPLAY set?)")
    vtecap.save(pb, out)


def build_fonts(args):
    fonts = args.fonts.split(",") if args.fonts else CODING

    def build(box):
        heading(box, args.title or f"Coding fonts as terminator (VTE) draws them, {args.size}pt")
        terms = []
        for fam in fonts:
            if not installed(fam):
                heading(box, f"{fam}: not installed", 9)
                continue
            text = (f"{E}1;33m{fam:<17}{E}0m o0O 1lI| `'\" {{}}[]() == != => -> <= >= :: www  ⎿ ⏸ ✅\n"
                    f"{'':17} {E}36mfn{E}0m main() {{ let x = a != b && c >= d; }} "
                    f"{E}32m// {E}1mbold{E}0m  powerline: {POWERLINE}")
            t = vtecap.terminal(f"{fam} {args.size}", text, 96)
            box.pack_start(t, False, False, 0)
            terms.append(t)
        return terms
    return build


def build_ligatures(args):
    def build(box):
        heading(box, args.title or "Ligatures: VTE (terminator, sakura) vs GTK/Pango (gedit; VS Code with editor.fontLigatures)")
        terms = []
        for fam in LIGATURE_FONTS:
            t = vtecap.terminal(f"{fam} {args.size}", f"{E}1;33m{fam + ' (VTE)':<22}{E}0m {LIG_TEXT}", 80)
            box.pack_start(t, False, False, 0)
            terms.append(t)
            gtk_label(box, fam, args.size, f"{fam + ' (GTK)':<22} {LIG_TEXT}")
        return terms
    return build


def build_icons(args):
    def build(box):
        heading(box, args.title or "Powerline and Nerd Font icons")
        heading(box, f"icons: {ICON_NAMES}", 9)
        terms = []
        for fam in ICON_FONTS:
            t = vtecap.terminal(f"{fam} {args.size}",
                                f"{E}1;33m{fam:<17}{E}0m powerline: {POWERLINE}   icons: {ICONS}", 72)
            box.pack_start(t, False, False, 0)
            terms.append(t)
        return terms
    return build


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("mode", choices=["fonts", "ligatures", "icons", "stack", "zoom"])
    ap.add_argument("inputs", nargs="*")
    ap.add_argument("--out", required=True)
    ap.add_argument("--title")
    ap.add_argument("--size", type=int, default=10)
    ap.add_argument("--fonts")
    ap.add_argument("--crop")
    ap.add_argument("--scale", type=int, default=4)
    args = ap.parse_intermixed_args()  # input files may come after the options

    if args.mode == "stack":
        vtecap.save(vtecap.stack([GdkPixbuf.Pixbuf.new_from_file(p) for p in args.inputs]), args.out)
    elif args.mode == "zoom":
        src = GdkPixbuf.Pixbuf.new_from_file(args.inputs[0])
        x, y, w, h = (int(v) for v in args.crop.split(",")) if args.crop else (0, 0, src.get_width(), src.get_height())
        sub = src.new_subpixbuf(x, y, w, h)
        vtecap.save(sub.scale_simple(w * args.scale, h * args.scale, GdkPixbuf.InterpType.NEAREST), args.out)
    else:
        builder = {"fonts": build_fonts, "ligatures": build_ligatures, "icons": build_icons}[args.mode]
        render(builder(args), args.out)


if __name__ == "__main__":
    main()
