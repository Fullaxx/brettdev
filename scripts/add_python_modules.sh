#!/bin/bash

set -e

apt-get update

apt-get install -y --no-install-recommends \
build-essential \
gdb \
python3-pip \
tmux

python3 -m pip install \
alpaca-py \
frogmouth \
gdbfrontend \
matplotlib \
pandas==2.1.4 \
pandas_ta \
pudb \
pyfinance \
pygments \
pyzmq \
redis[hiredis] \
xxhash \
yfinance

apt-get clean

rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
