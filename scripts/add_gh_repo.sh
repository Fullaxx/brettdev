#!/bin/bash

set -e

# gh comes from GitHub's own repository, because Ubuntu's (2.45 on noble) is broken by
# GitHub's API changes: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# Assume these are available (add_dev_tools.sh): ca-certificates curl

# Add GitHub CLI's GPG key:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli-archive-keyring.gpg
chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

# Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  >/etc/apt/sources.list.d/github-cli.list

apt-get update

apt-get install -y --no-install-recommends gh

apt-get clean
rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*
