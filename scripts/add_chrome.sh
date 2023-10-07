#!/bin/bash

set -e

#CHROMEURL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
#CHROMEDEB="/tmp/chrome.deb"

/app/scripts/install_chrome.sh
apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
