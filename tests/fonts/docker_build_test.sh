#!/bin/bash
#
# docker_build_test.sh - run scripts/add_fonts.sh in a throwaway image built FROM
# the bare ubuntu-desktop base, exactly as the real build runs it (including its
# /tmp cleanup), then run check_fonts.sh inside that image.
#
# It also probes what CJK would resolve to if fonts-droid-fallback got installed
# later (libgs10-common recommends it). The image is removed afterwards.
#
# Usage: tests/fonts/docker_build_test.sh
#   BASE=image  base image (default ghcr.io/fullaxx/ubuntu-desktop:latest)
#   TAG=name    test image tag (default brettdev-fonttest:tmp)
#   KEEP=1      keep the image afterwards (docker run --rm -it brettdev-fonttest:tmp bash)

set -e
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
BASE=${BASE:-ghcr.io/fullaxx/ubuntu-desktop:latest}
TAG=${TAG:-brettdev-fonttest:tmp}

ctx=$(mktemp -d "${TMPDIR:-/tmp}/fonttest-ctx.XXXXXX")
cleanup() {
	rm -rf "$ctx"
	[ -n "$KEEP" ] || docker rmi -f "$TAG" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cp "$repo/scripts/add_fonts.sh" "$here/check_fonts.sh" "$ctx/"
cat >"$ctx/Dockerfile" <<EOF
FROM $BASE
COPY add_fonts.sh check_fonts.sh /install/scripts/
RUN /install/scripts/add_fonts.sh
EOF

echo "=== building $TAG from $BASE ==="
docker build -t "$TAG" "$ctx"

# The RUN layer's own size. Subtracting `docker image inspect` totals overstates it:
# 291 MB vs 183 MB on Docker 29 with the containerd image store.
echo "=== the add_fonts.sh layer is $(docker history --format '{{.Size}}' "$TAG" | head -1) ==="

echo "=== check_fonts.sh inside the image ==="
status=0
docker run --rm "$TAG" /install/scripts/check_fonts.sh || status=$?

echo "=== probe: CJK resolution after installing fonts-droid-fallback ==="
docker run --rm "$TAG" bash -c '
	for p in "sans-serif:charset=4e2d" "sans-serif:lang=ja" "sans-serif:lang=ko" "sans-serif:lang=zh-cn"; do
		printf "  before  %-26s -> %s\n" "$p" "$(fc-match "$p" family)"
	done
	apt-get update -qq && apt-get install -y -qq --no-install-recommends fonts-droid-fallback >/dev/null 2>&1
	for p in "sans-serif:charset=4e2d" "sans-serif:lang=ja" "sans-serif:lang=ko" "sans-serif:lang=zh-cn"; do
		printf "  after   %-26s -> %s\n" "$p" "$(fc-match "$p" family)"
	done' || true

exit $status
