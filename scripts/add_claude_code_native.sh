#!/bin/bash

# Claude Code has switched from npm to native installer.
# Run `claude install` or see https://docs.anthropic.com/en/docs/claude-code/getting-started for more options.
curl -fsSL https://claude.ai/install.sh | bash

echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
