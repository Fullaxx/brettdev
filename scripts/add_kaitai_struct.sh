#!/bin/bash

set -e

KTVERS="0.11"
KTFILE="kaitai-struct-compiler_${KTVERS}_all.deb"

apt-get update
apt-get install -y --no-install-recommends ruby openjdk-8-jre-headless
wget https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/${KTVERS}/${KTFILE}
dpkg -i ${KTFILE}
rm ${KTFILE}
gem install kaitai-struct-visualizer
pip install kaitaistruct
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
