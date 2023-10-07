#!/bin/bash

set -e

/app/scripts/install_vscode_repo.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
