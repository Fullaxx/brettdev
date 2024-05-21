#!/bin/bash

set -e

DEB="drawio.deb"
DRAWIOVERS="24.4.0"
DRAWIOURL="https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIOVERS}/drawio-amd64-${DRAWIOVERS}.deb"

cd /tmp
wget ${DRAWIOURL} -O ${DEB}
dpkg -i ${DEB} || (set -e; apt-get update; apt-get install -f -y)
rm ${DEB}
