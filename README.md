# Ubuntu Desktop running Openbox in VNC for developers

## Base Docker Image
[fullaxx/ubuntu-desktop](https://www.github.com/Fullaxx/ubuntu-desktop)

## Images

| Image | Description |
|---|---|
| `ghcr.io/fullaxx/brettdev` | Base image: Ubuntu desktop + dev tools from the Ubuntu repo |
| `ghcr.io/fullaxx/brettdev-full` | Full image: brettdev + third-party tools (Claude, Bun, Docker, Postgres, Chrome, VSCode, etc.) |

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
docker build -t ghcr.io/fullaxx/brettdev .

# Build the full image (requires brettdev to be available locally or on ghcr.io)
docker build -t ghcr.io/fullaxx/brettdev-full -f Dockerfile.full .
```
