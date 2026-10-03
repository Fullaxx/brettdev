#!/bin/bash
#
# fcconf.sh - run a command under a private fontconfig configuration, so you can
# test font sets without installing or removing anything.
#
# Usage: tests/fonts/fcconf.sh [options] [DIR]... -- COMMAND [ARGS]...
#   (default)        the system config (/etc/fonts/fonts.conf) plus each DIR
#   --no-system      only the given DIRs: no system fonts and no system rules
#   --include CONF   load a fontconfig snippet before the system config, the way
#                    a 10-*.conf in /etc/fonts/conf.d would load
#   --reject GLOB    hide matching font files, e.g. to see what things looked like
#                    before a font was installed:
#                    --reject '/usr/local/share/fonts/nerd-fonts-symbols/*'
#
# Font caches for the extra dirs go to $FONTTEST_WORK/fccache, never to
# /var/cache/fontconfig: our <cachedir> comes first, and fontconfig writes to the
# first writable one. XDG_CACHE_HOME is pointed at the work dir too.
#
# Examples:
#   # What would terminator draw with only DejaVu installed?
#   tests/fonts/fcconf.sh --no-system /usr/share/fonts/truetype/dejavu -- \
#       tests/fonts/vte_render.py --out /tmp/dejavu-only.png
#   # Which fonts cover U+23BF if fonts-noto-core were added? (after debs.py fetch)
#   tests/fonts/fcconf.sh "$FONTTEST_WORK/fonts/fonts-noto-core" -- fc-list ':charset=23bf' family

set -e
WORK=${FONTTEST_WORK:-${TMPDIR:-/tmp}/fonttest}
system=1
includes=()
rejects=()
dirs=()
while [ $# -gt 0 ]; do
	case "$1" in
	--no-system) system= ; shift ;;
	--include) includes+=("$(readlink -f "$2")") ; shift 2 ;;
	--reject) rejects+=("$2") ; shift 2 ;;
	--) shift ; break ;;
	-h | --help) sed -n '2,29p' "$0" | sed 's/^# \{0,1\}//' ; exit 0 ;;
	*) dirs+=("$(readlink -f "$1")") ; shift ;;
	esac
done
if [ $# -eq 0 ]; then
	echo "usage: $0 [--no-system] [--include CONF]... [--reject GLOB]... [DIR]... -- COMMAND [ARGS]..." >&2
	exit 2
fi

mkdir -p "$WORK/fcconf" "$WORK/fccache" "$WORK/xdgcache"
key=$(printf '%s\n' "$system" "${includes[@]}" "${rejects[@]}" "${dirs[@]}" | md5sum | cut -c1-12)
conf="$WORK/fcconf/$key.conf"
{
	echo '<?xml version="1.0"?>'
	echo '<!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">'
	echo '<fontconfig>'
	echo "  <cachedir>$WORK/fccache</cachedir>"
	for i in "${includes[@]}"; do echo "  <include ignore_missing=\"no\">$i</include>"; done
	[ -n "$system" ] && echo '  <include ignore_missing="no">/etc/fonts/fonts.conf</include>'
	for d in "${dirs[@]}"; do echo "  <dir>$d</dir>"; done
	if [ ${#rejects[@]} -gt 0 ]; then
		echo '  <selectfont><rejectfont>'
		for g in "${rejects[@]}"; do echo "    <glob>$g</glob>"; done
		echo '  </rejectfont></selectfont>'
	fi
	echo '</fontconfig>'
} >"$conf"

unset FONTCONFIG_PATH
export FONTCONFIG_FILE="$conf" XDG_CACHE_HOME="$WORK/xdgcache"
exec "$@"
