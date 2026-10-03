#!/bin/bash
#
# glyphtest.sh - print the glyphs Claude Code draws, laid out like its UI, in
# whatever terminal runs this. A hex box means no installed font has that glyph.
#
# Usage: tests/fonts/glyphtest.sh [--hold]
#   --hold  start a shell afterwards, so a terminal opened just for this stays open:
#             terminator -u -x tests/fonts/glyphtest.sh --hold
#           -u matters: terminator runs single-instance over D-Bus, and only a new
#           process picks up fonts installed since the first window opened.

E=$'\e['
PL=$'  '                       # Powerline: branch, arrows
IC=$'   \U000f0219'             # Nerd icons: git-branch, git, folder, md-file
printf '\e]0;glyphtest\a'
printf '%s\n' \
	"${E}1;33mClaude Code glyph test${E}0m (hex boxes = no font for that glyph)" \
	"${E}90m❯${E}0m /plan" \
	"  ⎿  Enabled plan mode" \
	"${E}32m●${E}0m ${E}1mBash${E}0m(ls -la)" \
	"  ⎿  Allowed by auto mode classifier" \
	"${E}31m✽${E}0m ${E}33mElucidating…${E}0m (31s · ↓ 2.9k tokens)" \
	"  ${E}36m⏸ plan mode on${E}0m (shift+tab to cycle)   ${E}35m⏵⏵ accept edits on${E}0m" \
	"  ⏺ Update(app.py)   ⏹ stop   ⧉ In app.py   ⎯⎯⎯⎯⎯⎯" \
	"  spinner: ✻ ✽ ✶ ✳ ✢   todo: ☐ ☒ ✔ ✘   ⚠ warn  ◐ ◑" \
	"  emoji: ✅ done  ❌ fail  ✨ new  🤖 bot  🚀 ship" \
	"  CJK: 中文 日本語 한국어   powerline: ${PL}   icons: ${IC}"
[ "$1" = "--hold" ] && exec bash --norc
exit 0
