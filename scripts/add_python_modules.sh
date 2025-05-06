#!/bin/bash

set -e

apt-get update

apt-get install -y --no-install-recommends \
build-essential \
gdb \
python3-pip \
tmux

# seaborn pyqtgraph

python3 -m pip install \
alpaca-py \
frogmouth \
gdbfrontend \
grip \
ipython \
matplotlib \
pandas==2.1.4 \
pandas_ta \
pudb \
pyfinance \
pygments \
pyzmq \
redis[hiredis] \
rel \
scapy \
websocket-client \
wsaccel \
xxhash \
yfinance

apt-get clean

rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
