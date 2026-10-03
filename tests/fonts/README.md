# Font test toolkit

The tools used to investigate and fix this image's font problems, kept so the findings can be re-checked
after the base image, the package list or Ubuntu's packages change. Problems covered:
- Claude Code's UI glyphs drawn as hex boxes;
- missing emoji, CJK, MathML and icon fonts;
- choosing coding fonts.

What was found, and why each font is installed (or not), is written up in [`FONTS.md`](../../FONTS.md).

## Before you run anything

- **Never run `scripts/add_fonts.sh` in a running container.** It ends with
  `rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*`, which is meant for `docker build`. In a live desktop that
  deletes the D-Bus session socket and anything else in `/tmp`. Use `docker_build_test.sh`, or
  `apt-get install --no-install-recommends` the packages directly.
- **Nothing here installs packages**, except `docker_build_test.sh` inside a throwaway image.
- **Scratch output goes to `$FONTTEST_WORK`** (default `${TMPDIR:-/tmp}/fonttest`): package indexes,
  downloaded .debs, extracted fonts, private fontconfig configs and caches, and intermediate images. Set each
  variable in its own statement (`S=…; export FONTTEST_WORK=$S/fonttest`): in
  `export S=… FONTTEST_WORK=$S/fonttest`, the `$S` expands *before* `S` is set.
- **The GTK/VTE tools** (`vte_render.py`, `specimen.py`, `vte_native_glyphs.py`, `ligatures.py`, and
  `vtecap.py` behind them) need:
  - the system python, `/usr/bin/python3`, with PyGObject, GTK 3, VTE 2.91 and pycairo. Terminator's
    dependencies provide all of them, and the shebangs point there; the `/opt/venv` `python3` has no `gi`.
  - a `DISPLAY`. They draw into offscreen windows, so nothing appears on screen.
- **Network:** `debs.py` talks to archive.ubuntu.com. `upstream_versions.sh` uses the GitHub API, which
  allows 60 requests an hour without a token.

## Quick start

```bash
tests/fonts/check_fonts.sh                          # PASS/FAIL: does this system have what add_fonts.sh installs?
tests/fonts/docker_build_test.sh                    # run add_fonts.sh in a throwaway image, then check it
tests/fonts/make_doc_images.sh                      # regenerate docs/fonts/*.png
terminator -u -x tests/fonts/glyphtest.sh --hold    # look at it in a real terminal
```

## Tools

| Tool | What it does |
|---|---|
| `check_fonts.sh` | PASS/FAIL checks: every package in `add_fonts.sh` installed; Claude Code's UI glyphs and emoji covered; CJK resolves to Noto Sans CJK (with the right regional font for `ja`/`ko`/`zh-cn`) and Droid Sans Fallback is absent; Arial, Times New Roman and Courier New → Liberation, `Calibri` → Carlito, `Cambria` → Caladea; terminator's default `Liberation Mono` resolves to itself; STIX Math present; Nerd Font icons and their fontconfig snippet; `monospace` still DejaVu Sans Mono; every coding font present. Exits 1 on any failure. |
| `docker_build_test.sh` | Builds a throwaway image `FROM ghcr.io/fullaxx/ubuntu-desktop:latest`, runs `scripts/add_fonts.sh` exactly as the real build does, reports the layer size, runs `check_fonts.sh` inside, and probes what CJK resolves to if `fonts-droid-fallback` gets installed later. The image is removed afterwards (`KEEP=1` keeps it). |
| `debs.py` | Ubuntu archive without installing anything. `show [--grep RE] [--installed] PKG…` prints relations and sizes; `rdeps PKG` finds who depends on it or recommends it; `fetch PKG…` downloads and extracts .debs into `$FONTTEST_WORK/fonts/PKG`; `cat PKG FILE` prints one file from a .deb, in memory. |
| `fcconf.sh` | Runs a command under a private fontconfig: the system set plus extra dirs, only the given dirs (`--no-system`), early snippets (`--include`), or with fonts hidden (`--reject GLOB`). Tests "what if this font were (not) installed" without touching the system. |
| `glyph_coverage.py` | Scans the `claude` binary (or any file) for symbol codepoints, lists which UI glyphs have no font, and with `--candidates DIR` scores each extracted package. |
| `font_caps.py` | Per-family capabilities, read from the font files: version, styles, variable font, embedded bitmap sizes, MATH table, OpenType features (stylistic sets, character variants), Powerline/box/Braille/script/icon coverage. |
| `charset_diff.py` | Codepoints of family A missing from family B. |
| `ligatures.py` | Shapes code tokens with Pango with ligatures on and off; reports which tokens change, per font. |
| `script_coverage.sh` | ~30 writing systems → which installed font covers each (what a browser falls back to). |
| `vte_render.py` | A sample of Claude Code's UI in an offscreen `Vte.Terminal` (the widget terminator uses) → PNG. |
| `specimen.py` | Specimen sheets → PNG: `fonts` (every coding font in VTE), `ligatures` (VTE vs GTK), `icons` (Powerline/Nerd icons); plus `stack` and `zoom` image helpers. |
| `vte_native_glyphs.py` | ASCII-art probe: does VTE draw a character itself, or show a hex box when no font has it? |
| `vtecap.py` | Shared helpers for the three renderers. They capture offscreen and wait until VTE has actually drawn; a fixed delay sometimes grabbed blank frames. |
| `glyphtest.sh` | Prints Claude Code's glyphs, emoji, CJK, Powerline and icons in the current terminal. |
| `screenshot_window.sh` | Captures the window a process lives in (walks up the process tree, then `xdotool --pid`, `maim -i`); `--zoom` enlarges a region to read the codepoint inside a hex box. |
| `upstream_versions.sh` | Latest upstream release of each font next to noble's packaged version. |
| `make_doc_images.sh` | Regenerates `docs/fonts/*.png` with the tools above. |

## Recipes: how each finding was reached

```bash
S=${TMPDIR:-/tmp}; export FONTTEST_WORK=$S/fonttest
T=tests/fonts

# Which glyphs had no font, with the image's original fonts only?
$T/fcconf.sh --no-system /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/liberation -- $T/glyph_coverage.py

# Which candidate package would fix them?
$T/debs.py fetch fonts-noto-core fonts-noto-color-emoji fonts-symbola fonts-hack fonts-firacode
$T/fcconf.sh --no-system /usr/share/fonts/truetype/dejavu -- \
    $T/glyph_coverage.py --candidates "$FONTTEST_WORK/fonts" --combo fonts-noto-core+fonts-noto-color-emoji

# What can each coding font do?
$T/font_caps.py
$T/ligatures.py

# Does VTE draw Powerline glyphs itself? (Anonymous Pro has none, so only VTE could draw them)
$T/fcconf.sh --no-system /usr/share/fonts/truetype/anonymous-pro -- \
    $T/vte_native_glyphs.py --font "Anonymous Pro 20" e0a0 e0b0 e702

# Which writing systems would a browser show as tofu?
$T/script_coverage.sh --missing

# What do LibreOffice, Chrome and Firefox ask for?
$T/debs.py show --grep font libreoffice
$T/debs.py show --installed --grep 'font|emoji' google-chrome-stable firefox
$T/debs.py show fonts-noto                         # the metapackage: Depends core, Recommends the rest

# Is fonts-font-awesome needed? (fetch it first if it isn't installed)
$T/debs.py rdeps fonts-font-awesome
$T/debs.py fetch fonts-font-awesome
$T/fcconf.sh "$FONTTEST_WORK/fonts/fonts-font-awesome" -- \
    $T/charset_diff.py FontAwesome "Symbols Nerd Font" --range E000-F8FF

# Would fonts-droid-fallback hurt? Who'd pull it in, its rule, and the measured effect
$T/debs.py rdeps fonts-droid-fallback
$T/debs.py cat fonts-droid-fallback etc/fonts/conf.avail/65-droid-sans-fallback.conf
$T/docker_build_test.sh                            # see the "probe" section of its output

# Are the packaged versions current?
$T/upstream_versions.sh
```

## Findings (2026-10-03, brettdev-full on Ubuntu 24.04, VTE 0.76, Pango 1.52, fontconfig 2.15)

- **Hex boxes.** Before `add_fonts.sh`, `⎿ ⏵ ⏸ ⏺ ⏹ ⎯ ⧉` and every emoji had no font among the image's 21
  font families. `fonts-noto-core` covers the symbols and `fonts-noto-color-emoji` the emoji. No coding font
  covers any of them: `fonts-anonymous-pro` fixed 0 of the binary-wide set, and Hack 1.
- **Ligatures.** Fira Code 17/17 tokens, Cascadia Code 17/17, JetBrains Mono 16/17 (no `www`); every other
  coding font 0, including Cascadia Mono despite its `calt` feature. VTE never shows them.
- **Capabilities.**
  - noble's Cascadia (2102.03) has no italics and no Nerd Font variants (upstream 2407.24 has both).
  - Fira Code has no italics anywhere.
  - Anonymous Pro has bitmaps at 10–13 px.
  - Noto Sans Math has no MATH table; STIX Math does.
- **VTE and Powerline.** VTE draws Powerline codepoints as hex boxes when no font has them; it does not draw
  them itself.
- **Browsers.**
  - After `fonts-noto-core`, the only uncovered writing systems were CJK (Han, kana, Hangul).
  - Chrome bundles no fonts; Firefox bundles only Twemoji.
  - Firefox's MathML font list matched nothing installed.
- **Recommends we skip.** LibreOffice recommends 11 font packages, including Carlito/Caladea. The `fonts-noto`
  metapackage Depends only on `fonts-noto-core`; everything else (~770 MB) is a Recommend.
  `fonts-noto-extra` is 1,540 files of extra weights, with no new scripts.
- **FontAwesome.** All 694 FontAwesome 4.7 icons are in Symbols Nerd Font. 79 noble packages depend on or
  recommend `fonts-font-awesome`, mostly web apps and documentation; here only `ntopng-data` did.
- **Droid takeover.** `libgs10-common` recommends `fonts-droid-fallback`. Installed, it takes Japanese-tagged
  text from Noto Sans CJK JP; untagged, Korean and Chinese text stayed on Noto.
- **Generic families.** `sans-serif` → Noto Sans once `fonts-noto-core` is in; `monospace` stays DejaVu Sans
  Mono.
- **Terminator's default font.**
  - `fonts-liberation` used to arrive only with Chrome, in `brettdev-full` (Chrome's installer runs
    `apt-get install -f` with recommends on). In plain `brettdev`, terminator's `Liberation Mono 9` resolved to
    Nimbus Mono PS, URW's Courier clone.
  - `add_fonts.sh` now installs `fonts-liberation`.
  - Its recommended `fonts-liberation-sans-narrow` stays out, so Arial Narrow falls back to Nimbus Sans Narrow.
- **Size.** `add_fonts.sh` adds one 188 MB layer on the bare base (`docker history`). Noto CJK is 91 MB of
  that.
