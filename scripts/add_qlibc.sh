#!/bin/bash

set -e

QLIBCVERS="2.5.1"
QLIBCURL="https://github.com/wolkykim/qlibc/archive/refs/tags/v${QLIBCVERS}.tar.gz"

mkdir -p /opt/code
cd /opt/code
curl -L ${QLIBCURL} -o qlibc-${QLIBCVERS}.tar.gz
tar xf qlibc-${QLIBCVERS}.tar.gz
cd qlibc-${QLIBCVERS}
./configure --prefix=/usr --libdir=/usr/lib64
make
make install
cd src
doxygen doxygen.conf
mkdir /usr/share/doc/qlibc-${QLIBCVERS}
cd /opt/code
cp -r qlibc-${QLIBCVERS}/doc/html /usr/share/doc/qlibc-${QLIBCVERS}/
# Only the extracted build directory is removed here -- the downloaded
# qlibc-${QLIBCVERS}.tar.gz is intentionally left behind in /opt/code.
# brettdev is an interactive dev image, and keeping the source tarball
# around means it's there to re-extract and read through later, without
# needing network access again just to look at how something works.
rm -rf qlibc-${QLIBCVERS}

# --libdir=/usr/lib64 above puts the .so where ldconfig doesn't look by
# default on Debian/Ubuntu (only /usr/lib/x86_64-linux-gnu and friends are
# in /etc/ld.so.conf.d/*.conf out of the box -- /usr/lib64 isn't a path
# Debian/Ubuntu's linker config expects). Without this, a program that
# actually calls into libqlibc fails at runtime with "cannot open shared
# object file" even though the .so is sitting right there on disk and
# `ldconfig` was run -- ldconfig only rebuilds its cache from directories
# it's been told to look in.
echo /usr/lib64 > /etc/ld.so.conf.d/qlibc.conf
ldconfig
