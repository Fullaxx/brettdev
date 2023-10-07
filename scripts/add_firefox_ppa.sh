#!/bin/bash

set -e

/app/scripts/prepare_firefox_ppa.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
