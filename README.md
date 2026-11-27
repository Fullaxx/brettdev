# Ubuntu Desktop running Openbox in VNC for developers

**This is the `24.04` branch:** Ubuntu 24.04 (noble), published as `ghcr.io/fullaxx/brettdev:24.04` and `ghcr.io/fullaxx/brettdev-full:24.04`, also as `:noble`. \
It gets maintenance updates and hand-picked features. For the latest release (Ubuntu 26.04: `:latest`, `:26.04` and `:resolute`), see the `master` branch and its [branches and tags](https://github.com/Fullaxx/brettdev#branches-and-tags).

## Base Docker Image
[fullaxx/ubuntu-desktop](https://www.github.com/Fullaxx/ubuntu-desktop) 24.04 (x64)

## Images

| Image | Description |
|---|---|
| `ghcr.io/fullaxx/brettdev` | Base image: Ubuntu desktop + dev tools from the Ubuntu repo |
| `ghcr.io/fullaxx/brettdev-full` | Full image: brettdev + third-party tools (Claude, Bun, Docker, Postgres, Chrome, VSCode, etc.) |

## Get the images
```
docker pull ghcr.io/fullaxx/brettdev:24.04
docker pull ghcr.io/fullaxx/brettdev-full:24.04
```

## Python and Go environment

Python packages from `requirements.txt` live in a virtual environment at `/opt/venv`. The Dockerfile `ENV`
directives put it (and, in brettdev-full, Go) on `PATH` at build time; inside the VNC desktop,
`conf/etc_bash_bashrc` (appended to `/etc/bash.bashrc`) does it for every terminal. Both are needed — see
[PYTHON_VENV.md](PYTHON_VENV.md) for why.

## Fonts

`scripts/add_fonts.sh` installs the image's fonts:
- fallback fonts, so symbols (including Claude Code's UI glyphs), emoji and CJK render instead of showing as
  hex boxes;
- fonts compatible with Microsoft Office's (Arial, Times New Roman, Courier New, Calibri, Cambria) and a
  MathML font;
- a set of coding fonts;
- Nerd Font icons.

See [FONTS.md](FONTS.md) for what each font provides, where ligatures work, and the gotchas. The tools in
[tests/fonts/](tests/fonts/README.md) re-check all of it; start with `tests/fonts/check_fonts.sh`.

## Build locally
```
# Build the base image
docker build -t ghcr.io/fullaxx/brettdev:24.04 .

# Build the full image (requires brettdev:24.04 to be available locally or on ghcr.io)
docker build -t ghcr.io/fullaxx/brettdev-full:24.04 -f Dockerfile.full .
```
