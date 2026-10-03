#!/bin/bash
#
# upstream_versions.sh - each font's latest upstream release next to the version
# noble packages, to spot stale packages.
#
# Usage: tests/fonts/upstream_versions.sh
#   Calls the GitHub API without a token (60 requests an hour) and debs.py for noble.
#
# Found on 2026-10-03:
#   - fonts-cascadia-code is 2102.03 vs upstream v2407.24: no italics, no Nerd Font
#     variants.
#   - fonts-font-awesome is Font Awesome 4.7 vs 7.3.1.
#   - fonts-inconsolata is 001.010 vs 3.000.
#   - Fira Code, Hack and JetBrains Mono match upstream.

here=$(cd "$(dirname "$0")" && pwd)
printf '%-26s %-26s %-28s %s\n' "upstream repo" "latest release" "noble package" "noble version"
while read -r repo pkg; do
	[ -z "$repo" ] && continue
	up=$(curl -s -m 20 "https://api.github.com/repos/$repo/releases/latest" |
		python3 -c 'import sys, json; d = json.load(sys.stdin); print(d.get("tag_name", "?"), (d.get("published_at") or "")[:10])' 2>/dev/null)
	if [ "$pkg" = "-" ]; then
		deb="(not packaged)"
	else
		deb=$("$here/debs.py" show "$pkg" 2>/dev/null | head -1 | awk '{print $2}')
	fi
	printf '%-26s %-26s %-28s %s\n' "$repo" "${up:-?}" "$pkg" "${deb:-?}"
done <<'EOF'
microsoft/cascadia-code fonts-cascadia-code
tonsky/FiraCode fonts-firacode
source-foundry/Hack fonts-hack
JetBrains/JetBrainsMono fonts-jetbrains-mono
madmalik/mononoki fonts-mononoki
googlefonts/Inconsolata fonts-inconsolata
googlefonts/noto-emoji fonts-noto-color-emoji
notofonts/noto-cjk fonts-noto-cjk
FortAwesome/Font-Awesome fonts-font-awesome
ryanoasis/nerd-fonts -
be5invis/Iosevka -
githubnext/monaspace -
EOF
