#!/bin/bash

set -e

# Ubuntu 26.04 images don't ship the unminimize command
# (24.04's had the unminimize package preinstalled),
# so install it first
apt-get update
apt-get install -y --no-install-recommends unminimize

# The base image is minimized: no man pages or docs,
# and man is only a stub. unminimize restores them,
# also for everything installed after this step.
# yes answers its confirmation prompts.
yes | unminimize
apt-get upgrade -y
apt-get install -y --no-install-recommends \
	man-db \
	manpages-dev \
	manpages-posix-dev
# apt-get autoremove -y --purge
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
