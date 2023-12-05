#!/bin/bash

set -e

LGVERS="0.40.2"
LGURL="https://github.com/jesseduffield/lazygit/releases/download/v${LGVERS}/lazygit_${LGVERS}_Linux_x86_64.tar.gz"

mkdir -p /usr/share/doc/lazygit-${LGVERS}
cd /usr/share/doc/lazygit-${LGVERS}
wget ${LGURL} -O lazygit.tar.gz
tar xvf lazygit.tar.gz
rm lazygit.tar.gz
mv lazygit /usr/bin/
