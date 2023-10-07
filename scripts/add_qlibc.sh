#!/bin/bash

set -e

QLIBCVERS="2.5.0"
QLIBCURL="https://github.com/wolkykim/qlibc/archive/refs/tags/v${QLIBCVERS}.tar.gz"

cd /tmp
curl -L ${QLIBCURL} -o qlibc-${QLIBCVERS}.tar.gz
tar xf qlibc-${QLIBCVERS}.tar.gz
cd qlibc-${QLIBCVERS}
./configure --prefix=/usr --libdir=/usr/lib64
make
make install
cd src
doxygen doxygen.conf
mkdir /usr/share/doc/qlibc-${QLIBCVERS}
cd /tmp
cp -r qlibc-${QLIBCVERS}/doc/html /usr/share/doc/qlibc-${QLIBCVERS}/
rm -rf qlibc-${QLIBCVERS} qlibc-${QLIBCVERS}.tar.gz
ldconfig