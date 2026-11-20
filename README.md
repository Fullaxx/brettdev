# Ubuntu Desktop running Openbox in VNC for developers

## Base Docker Image
[fullaxx/ubuntu-desktop](https://www.github.com/Fullaxx/ubuntu-desktop) 26.04 (x64), and 24.04 on its own branch

## Images

| Image | Description |
|---|---|
| `ghcr.io/fullaxx/brettdev` | Base image: Ubuntu desktop + dev tools from the Ubuntu repo |
| `ghcr.io/fullaxx/brettdev-full` | Full image: brettdev + third-party tools (Claude, Bun, Docker, Postgres, Chrome, VSCode, etc.) |

## Branches and tags
Each branch publishes its own tags of both images, rebuilt at every push:

| Tag | Branch | Ubuntu | Python | GCC |
| --- | --- | --- | --- | --- |
| `:latest`, `:26.04` | [`master`](https://github.com/Fullaxx/brettdev/tree/master) | 26.04 (resolute) | 3.14 | 15 |
| `:24.04` | [`24.04`](https://github.com/Fullaxx/brettdev/tree/24.04) | 24.04 (noble) | 3.12 | 13 |

- `:latest` tracks 26.04: every push to `master` publishes the same images as `:latest` and `:26.04`.
- `24.04` gets maintenance updates and hand-picked features. Its README uses `:24.04` in every example.
- Every push to `master` is also tagged `master-<short commit>`. These tags never move.
- The examples below use `:latest`. Everything in this README works the same with `:26.04`.

## Get the images
```
docker pull ghcr.io/fullaxx/brettdev
docker pull ghcr.io/fullaxx/brettdev:26.04
docker pull ghcr.io/fullaxx/brettdev:24.04
docker pull ghcr.io/fullaxx/brettdev-full
docker pull ghcr.io/fullaxx/brettdev-full:26.04
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
docker build -t ghcr.io/fullaxx/brettdev .

# Build the full image (requires brettdev to be available locally or on ghcr.io)
docker build -t ghcr.io/fullaxx/brettdev-full -f Dockerfile.full .
```
