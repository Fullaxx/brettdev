#!/bin/bash

set -e

# Claude Code has switched from npm to native installer.
# Run `claude install` or see https://docs.anthropic.com/en/docs/claude-code/getting-started for more options.
curl -fsSL https://claude.ai/install.sh | bash

# Runtime PATH for ~/.local/bin (claude) is set in conf/etc_bash_bashrc (-> /etc/bash.bashrc), not /etc/profile.d: desktop terminals are non-login shells.
