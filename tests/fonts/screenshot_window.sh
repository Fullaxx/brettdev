#!/bin/bash
#
# screenshot_window.sh - capture the X window a process lives in. By default that's
# the terminal running this script, e.g. the one Claude Code runs in.
#
# Usage: tests/fonts/screenshot_window.sh [--pid PID] [--out FILE.png] [--zoom X,Y,W,H] [--scale N]
#   Walks up the process tree from PID (default: this script) until a process owns
#   a visible window, then captures that window with `maim -i`. It goes by process
#   because the *active* window is often a different terminal.
#   --zoom also writes FILE-zoom.png: that region enlarged N times (default 8),
#   enough to read the codepoint printed inside a hex box.
#
# Needs DISPLAY, xdotool and maim; --zoom also needs /usr/bin/python3 with GTK (it
# uses specimen.py zoom).
#
# How it was used on 2026-10-03: the Claude Code window showed boxes reading
# "23B…" (⎿ U+23BF) in front of every tool result and "23F…" (⏸ U+23F8) before
# "plan mode on".

set -e
here=$(cd "$(dirname "$0")" && pwd)
pid=$$
out=window.png
zoom=
scale=8
while [ $# -gt 0 ]; do
	case "$1" in
	--pid) pid=$2 ; shift 2 ;;
	--out) out=$2 ; shift 2 ;;
	--zoom) zoom=$2 ; shift 2 ;;
	--scale) scale=$2 ; shift 2 ;;
	-h | --help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//' ; exit 0 ;;
	*) echo "unknown option: $1" >&2 ; exit 2 ;;
	esac
done

win=
p=$pid
while [ -n "$p" ] && [ "$p" -gt 1 ]; do
	win=$(xdotool search --onlyvisible --pid "$p" 2>/dev/null | tail -1)
	[ -n "$win" ] && break
	p=$(ps -o ppid= -p "$p" | tr -d ' ')
done
if [ -z "$win" ]; then
	echo "no visible window owned by pid $pid or its ancestors" >&2
	exit 1
fi
echo "window $win \"$(xdotool getwindowname "$win")\" owned by pid $p ($(ps -o comm= -p "$p"))"
maim -i "$win" "$out"
echo "wrote $out"
if [ -n "$zoom" ]; then
	"$here/specimen.py" zoom --crop "$zoom" --scale "$scale" --out "${out%.png}-zoom.png" "$out"
fi
