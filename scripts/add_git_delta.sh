#!/bin/bash

set -e

GITDELTAVERS="0.16.5"
GITDELTAURL="https://github.com/dandavison/delta/releases/download/${GITDELTAVERS}/git-delta_${GITDELTAVERS}_amd64.deb"

wget ${GITDELTAURL}
dpkg -i git-delta_${GITDELTAVERS}_amd64.deb
rm git-delta_${GITDELTAVERS}_amd64.deb
