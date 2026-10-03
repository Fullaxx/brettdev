#!/bin/bash

set -e

# Symbols-only Nerd Font: the icon glyphs (devicons, octicons, codicons,
# Font Awesome, Material Design, powerline) that lazygit, starship, eza and
# nvim plugins draw. Not packaged for noble. Upstream's fontconfig snippet
# makes "monospace" and ~400 coding font families prefer it for those
# codepoints, so icons render no matter which font the terminal uses.

NFVERS="3.5.1"
NFURL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NFVERS}/NerdFontsSymbolsOnly.tar.xz"
NFFILE="NerdFontsSymbolsOnly.tar.xz"
NFFONTDIR="/usr/local/share/fonts/nerd-fonts-symbols"

mkdir -p /usr/share/doc/nerd-fonts-symbols-${NFVERS}
cd /usr/share/doc/nerd-fonts-symbols-${NFVERS}
wget ${NFURL} -O ${NFFILE}
tar xvf ${NFFILE} --no-same-owner
rm ${NFFILE}

mkdir -p ${NFFONTDIR}
mv *.ttf ${NFFONTDIR}/
mv 10-nerd-font-symbols.conf /etc/fonts/conf.avail/
ln -sf ../conf.avail/10-nerd-font-symbols.conf /etc/fonts/conf.d/

fc-cache -f
