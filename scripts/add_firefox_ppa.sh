#!/bin/bash

set -e

# _direct adds the PPA by hand instead of with add-apt-repository; see its header
/app/scripts/prepare_mozilla_ppa_direct.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
