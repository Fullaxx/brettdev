#!/bin/bash

set -e

DOCKERVERS="28.4.0"
TMPDIR=`mktemp -d`

wget https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERS}.tgz -O /tmp/docker.tgz
tar xf /tmp/docker.tgz -C ${TMPDIR}
cp -av ${TMPDIR}/docker/docker /usr/bin/
rm -rf ${TMPDIR} /tmp/docker.tgz
