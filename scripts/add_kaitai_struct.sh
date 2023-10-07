#!/bin/bash

set -e

apt-get update
apt-get install -y --no-install-recommends ruby openjdk-8-jre-headless
wget https://github.com/kaitai-io/kaitai_struct_compiler/releases/download/0.10/kaitai-struct-compiler_0.10_all.deb
dpkg -i kaitai-struct-compiler_0.10_all.deb
rm kaitai-struct-compiler_0.10_all.deb
gem install kaitai-struct-visualizer
pip install kaitaistruct
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
