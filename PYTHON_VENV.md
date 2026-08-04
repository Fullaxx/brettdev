# Python Packaging and PEP 668

This image installs a large set of Python packages from `requirements.txt` (finance/data-science tooling, dev utilities, etc.) via `scripts/add_dev_tools.sh` at build time. This document explains why that install goes into a virtual environment instead of the system Python, and the problem that avoids.

## The problem

Since Ubuntu 24.04 (Noble) / Debian 12, the system Python is marked as an **"externally managed environment"** per [PEP 668](https://peps.python.org/pep-0668/). A marker file at `/usr/lib/python3.*/EXTERNALLY-MANAGED` makes `pip install` refuse to run against the system interpreter:

```
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.
```

This isn't a bug — it's intentional. On Debian/Ubuntu, `apt`/`dpkg` owns `/usr/lib/python3/dist-packages` and tracks exactly what's installed there as part of the OS package database. If `pip` is allowed to install or upgrade packages into that same location, it can silently overwrite files `dpkg` believes it owns, corrupt the package database's consistency, or break OS tools that depend on specific versions of those packages. PEP 668 exists specifically to stop `pip` from doing that by default.

## The anti-pattern this image used to use

The original approach (up through commit `5d3b390`) simply deleted the marker file and installed into the user's home directory:

```bash
apt-get install -y --no-install-recommends thonny python3-pip
rm /usr/lib/python3*/EXTERNALLY-MANAGED
pip3 install --user -r /install/requirements.txt
```

`rm .../EXTERNALLY-MANAGED` "fixes" the error message, but it doesn't fix anything real — it just disables the safety check PEP 668 added. `--user` softens the blast radius slightly (installing to `~/.local/lib/python3.x/site-packages` rather than directly into `dist-packages`), but it's still an uncontained, ad hoc install path that depends on `$HOME`, requires its own separate `PATH` entry (`~/.local/bin`), and doesn't stop `pip` from being willing to touch the system Python at all going forward.

## The fix: a real virtual environment

This was replaced in commit `e6f0b6f6d8a41efab99cf3a5f905f4d99357d869`. `scripts/add_dev_tools.sh` now does:

```bash
apt-get install -y --no-install-recommends thonny python3-pip python3-venv python3-dev

python3 -m venv /opt/venv
/opt/venv/bin/pip install -r /install/requirements.txt
```

- `python3-venv` provides the stdlib `venv` module; `python3-dev` provides the headers packages need to build C extensions.
- `python3 -m venv /opt/venv` (no `--system-site-packages`) creates an isolated interpreter and `site-packages` entirely under `/opt/venv` — it cannot write into `/usr/lib/python3/dist-packages` no matter what, so it's structurally incapable of touching anything `apt`/`dpkg` manages.
- The system Python's `EXTERNALLY-MANAGED` marker is left alone, exactly as PEP 668 intends.

### Exposing the venv on `PATH`

`Dockerfile` sets:

```dockerfile
ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"
```

right alongside the other environment variables, near the top of the build. Because Docker `ENV` instructions are inherited through `FROM`, this makes `/opt/venv/bin` the default `python3`/`pip3` everywhere — interactive shells, non-interactive `RUN`/`CMD`/`ENTRYPOINT` steps in this Dockerfile, and every layered install script in `Dockerfile.full` (which builds `FROM ghcr.io/fullaxx/brettdev:latest`) — with no `source .../activate` required anywhere.

This image originally exposed the venv only via `conf/etc_bash_bashrc` (copied in and appended to `/etc/bash.bashrc`), which works for interactive shells but not for non-interactive build steps or downstream images. That was replaced with the `ENV`-based approach above once it was confirmed safe: every script in `scripts/` and the inherited base image's startup chain (`app.sh` → `imagestart.sh` → `tiger.sh`) were checked and found to contain no bare `python3`/`pip` invocations that a global `PATH` change could redirect, and both `Dockerfile` and `Dockerfile.full` build cleanly end-to-end with it in place. The same mechanism is used in the `fullaxx/ubrun` and `fullaxx/ubdev` images, where it was introduced first.

## Reference

[PEP 668 – Marking Python base environments as "externally managed"](https://peps.python.org/pep-0668/)
