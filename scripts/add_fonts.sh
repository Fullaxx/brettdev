#!/bin/bash

set -e

apt-get update

# What each package provides, and why: FONTS.md
#   fontconfig:     fc-cache, run at the end of this script
#   Glyph fallback: fonts-noto-core, fonts-noto-cjk, fonts-noto-color-emoji
#   Office metrics: fonts-liberation (Arial, Times New Roman, Courier New; also
#                   terminator's default Liberation Mono), fonts-crosextra-carlito
#                   (Calibri), fonts-crosextra-caladea (Cambria)
#   MathML:         fonts-stix (STIX Math)
#   Coding fonts:   everything else
# Deliberately left out: fonts-droid-fallback (its fontconfig rule takes CJK
# away from Noto) and fonts-font-awesome (Font Awesome 4.7, which the Symbols
# Nerd Font below already covers).
apt-get install -y --no-install-recommends \
fontconfig \
fonts-anonymous-pro \
fonts-cascadia-code \
fonts-crosextra-caladea \
fonts-crosextra-carlito \
fonts-firacode \
fonts-go \
fonts-hack \
fonts-jetbrains-mono \
fonts-liberation \
fonts-mononoki \
fonts-noto-cjk \
fonts-noto-color-emoji \
fonts-noto-core \
fonts-stix \
fonts-ubuntu

apt-get clean

rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

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
