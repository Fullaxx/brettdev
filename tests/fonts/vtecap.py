"""vtecap.py - shared helpers for rendering text offscreen with VTE (the terminal
widget terminator, sakura and GNOME Terminal use) and GTK, and saving PNGs.

Imported by vte_render.py, specimen.py and vte_native_glyphs.py. It needs the
system python with PyGObject, GTK 3 and VTE 2.91 (/usr/bin/python3 in this image;
the /opt/venv python3 has no `gi`). Nothing appears on screen: everything is drawn
into a Gtk.OffscreenWindow, but a display connection (DISPLAY) is still required.

Captures poll until the widgets have actually been drawn. A fixed delay
sometimes grabbed a blank frame.
"""
import os

os.environ.setdefault("NO_AT_BRIDGE", "1")  # silence the accessibility-bus warning

import gi  # noqa: E402

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("Vte", "2.91")
gi.require_version("Pango", "1.0")
gi.require_version("GdkPixbuf", "2.0")
from gi.repository import Gdk, GdkPixbuf, GLib, Gtk, Pango, Vte  # noqa: E402

FG, BG, PAGE = "#ebdbb2", "#000000", "#1d2021"


def rgba(spec):
    c = Gdk.RGBA()
    c.parse(spec)
    return c


def style_page():
    css = Gtk.CssProvider()
    css.load_from_data(f"window, box {{ background-color: {PAGE}; }} label {{ color: {FG}; }}".encode())
    Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css, Gtk.STYLE_PROVIDER_PRIORITY_USER)


def terminal(font, text, cols, rows=None, fg=FG, bg=BG):
    """A Vte.Terminal showing `text` (lines joined with CRLF, ANSI escapes allowed)."""
    lines = text.split("\n")
    t = Vte.Terminal()
    t.set_font(Pango.FontDescription(font))
    t.set_colors(rgba(fg), rgba(bg), None)
    t.set_cursor_blink_mode(Vte.CursorBlinkMode.OFF)
    t.set_size(cols, rows or len(lines))
    t.feed(("\r\n".join(lines) + "\x1b[?25l").encode())  # hide the cursor
    t._cells = (cols, rows or len(lines))
    return t


def size_terminals(widgets):
    """After show_all: pin each terminal to exactly cols x rows character cells."""
    for t in widgets:
        if isinstance(t, Vte.Terminal):
            cols, rows = t._cells
            t.set_size_request(cols * t.get_char_width() + 2, rows * t.get_char_height() + 2)


def bright_pixels(pb, x=0, y=0, w=None, h=None, threshold=110, step=1):
    """How many pixels in the region (sampling every `step`th row and column)
    have a red channel above threshold."""
    w = pb.get_width() - x if w is None else w
    h = pb.get_height() - y if h is None else h
    px, rs, nc = pb.get_pixels(), pb.get_rowstride(), pb.get_n_channels()
    return sum(1 for yy in range(y, y + h, step) for xx in range(x, x + w, step)
               if px[yy * rs + xx * nc] > threshold)


def drawn(pb, terms, minimum=10):
    """True once every terminal's own area contains some drawn text. GTK labels on
    the same page draw sooner, so checking the whole image isn't enough."""
    for t in terms:
        a = t.get_allocation()
        w, h = min(a.width, pb.get_width() - a.x), min(a.height, pb.get_height() - a.y)
        if w <= 0 or h <= 0 or bright_pixels(pb, a.x, a.y, w, h, step=2) < minimum:
            return False
    return True


def capture(window, ready=None, timeout_ms=15000):
    """Show `window` offscreen and return its pixbuf once ready(pixbuf) is true.

    The default readiness test is "some text has been drawn". Returns None on timeout."""
    ready = ready or (lambda pb: bright_pixels(pb, step=3) > 20)
    result = {}

    def poll():
        window.queue_draw()
        pb = window.get_pixbuf()
        if pb is not None and ready(pb):
            result["pb"] = pb.copy()
            Gtk.main_quit()
            return False
        return True

    def give_up():
        Gtk.main_quit()
        return False

    GLib.timeout_add(250, poll)
    GLib.timeout_add(timeout_ms, give_up)
    Gtk.main()
    return result.get("pb")


def stack(pixbufs, gap=6, bg=PAGE):
    """Stack pixbufs vertically onto one background."""
    pixbufs = [p if p.get_has_alpha() else p.add_alpha(False, 0, 0, 0) for p in pixbufs]
    w = max(p.get_width() for p in pixbufs)
    h = sum(p.get_height() for p in pixbufs) + gap * (len(pixbufs) - 1)
    out = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, w, h)
    c = rgba(bg)
    out.fill((int(c.red * 255) << 24) | (int(c.green * 255) << 16) | (int(c.blue * 255) << 8) | 0xFF)
    y = 0
    for p in pixbufs:
        p.copy_area(0, 0, p.get_width(), p.get_height(), out, 0, y)
        y += p.get_height() + gap
    return out


def save(pb, path):
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    pb.savev(path, "png", ["compression"], ["9"])
    print(f"wrote {path} ({pb.get_width()}x{pb.get_height()})")
