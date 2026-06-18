# Ubuntu Desktop running Openbox in VNC for developers

## Base Docker Image
[fullaxx/ubuntu-desktop](https://www.github.com/Fullaxx/ubuntu-desktop)

## Images

| Image | Description |
|---|---|
| `ghcr.io/fullaxx/brettdev` | Base image: Ubuntu desktop + dev tools from the Ubuntu repo |
| `ghcr.io/fullaxx/brettdev-full` | Full image: brettdev + third-party tools (Claude, Bun, Docker, Postgres, Chrome, VSCode, etc.) |

## Build locally
```
# Build the base image
docker build -t ghcr.io/fullaxx/brettdev .

# Build the full image (requires brettdev to be available locally or on ghcr.io)
docker build -t ghcr.io/fullaxx/brettdev-full -f Dockerfile.full .
```
