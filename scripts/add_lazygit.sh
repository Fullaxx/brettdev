#!/bin/bash

set -e

LGVERS="0.44.1"
LGURL="https://github.com/jesseduffield/lazygit/releases/download/v${LGVERS}/lazygit_${LGVERS}_Linux_x86_64.tar.gz"
LGFILE="lazygit.tar.gz"

mkdir -p /usr/share/doc/lazygit-${LGVERS}
cd /usr/share/doc/lazygit-${LGVERS}
wget ${LGURL} -O ${LGFILE}
tar xvf ${LGFILE}
rm ${LGFILE}
mv lazygit /usr/bin/
