#!/bin/bash

set -e

# Install bun
curl -fsSL https://bun.sh/install | bash

# check for bunx
cd /root/.bun/bin
if [ ! -L bunx ]; then
  ln -s bun bunx
fi

# Runtime BUN_INSTALL and ~/.bun/bin on PATH are set in conf/etc_bash_bashrc (-> /etc/bash.bashrc).
