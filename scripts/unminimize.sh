#!/bin/bash

set -e

yes | unminimize
apt-get update
apt-get upgrade -y
apt-get install -y --no-install-recommends \
	man-db \
	manpages-dev \
	manpages-posix-dev
# apt-get autoremove -y --purge
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
