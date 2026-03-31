#!/bin/bash

# Install bun
curl -fsSL https://bun.sh/install | bash

# check for bunx
cd /root/.bun/bin
if [ ! -L bunx ]; then
  ln -s bun bunx
fi

#export BUN_INSTALL="$HOME/.bun"
#export PATH="${BUN_INSTALL}/bin:$PATH"
