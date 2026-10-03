#!/bin/bash
#
# check_fonts.sh - check that the fonts scripts/add_fonts.sh installs are present,
# and that fontconfig resolves the cases FONTS.md describes.
#
# Usage: tests/fonts/check_fonts.sh
#   Prints PASS / FAIL / INFO lines. Exits 0 if everything passed, 1 otherwise.
#   Runs wherever fontconfig is installed: the live container, or a test image
#   (docker_build_test.sh copies it next to add_fonts.sh in /install/scripts/).

here=$(cd "$(dirname "$0")" && pwd)
fails=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }
info() { printf 'INFO  %s\n' "$1"; }

# expect_cover HEX FAMILY WHAT: some font covering U+HEX must belong to FAMILY
expect_cover() {
	local fams
	fams=$(fc-list ":charset=$1" family | sort -u | tr '\n' ';')
	if [[ "$fams" == *"$2"* ]]; then
		pass "U+${1^^} $3 -> $2"
	else
		fail "U+${1^^} $3: expected $2, got: ${fams:-no font at all}"
	fi
}

# expect_match PATTERN FAMILY WHAT: fc-match PATTERN must resolve to FAMILY
expect_match() {
	local got
	got=$(fc-match "$1" family)
	if [[ "$got" == *"$2"* ]]; then
		pass "$3: '$1' -> $got"
	else
		fail "$3: '$1' expected $2, got $got"
	fi
}

echo "--- packages from add_fonts.sh ---"
script=""
for f in "$here/../../scripts/add_fonts.sh" /install/scripts/add_fonts.sh "$here/add_fonts.sh"; do
	[ -f "$f" ] && { script=$f; break; }
done
if [ -n "$script" ]; then
	for pkg in $(grep -E '^fonts?(config|-[a-z0-9-]+) *\\?$' "$script" | tr -d ' \\'); do
		if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'ok installed'; then
			pass "package $pkg installed"
		else
			fail "package $pkg not installed"
		fi
	done
else
	info "add_fonts.sh not found; skipping package checks"
fi

echo "--- Claude Code UI glyphs and emoji ---"
expect_cover 23bf "Noto Sans Symbols" "tool-result connector"
expect_cover 23f5 "Noto Sans Symbols2" "accept-edits indicator"
expect_cover 23f8 "Noto Sans Symbols2" "plan-mode indicator"
expect_cover 29c9 "Noto Sans Math" "IDE selection marker"
expect_cover 2705 "Noto Color Emoji" "emoji check mark"
expect_cover 1f916 "Noto Color Emoji" "emoji robot"

echo "--- CJK (browsers, terminals, LibreOffice) ---"
expect_match "sans-serif:charset=4e2d" "Noto Sans CJK" "untagged Han"
expect_match "sans-serif:lang=ja" "Noto Sans CJK JP" "Japanese"
expect_match "sans-serif:lang=ko" "Noto Sans CJK KR" "Korean"
expect_match "sans-serif:lang=zh-cn" "Noto Sans CJK SC" "Simplified Chinese"
expect_match "serif:lang=ja" "Noto Serif CJK JP" "Japanese serif"
if [ -n "$(fc-list 'Droid Sans Fallback' family)" ]; then
	fail "Droid Sans Fallback is installed; its 65-droid-sans-fallback.conf takes CJK away from Noto (see FONTS.md)"
else
	pass "Droid Sans Fallback not installed"
fi

echo "--- office metric stand-ins and math ---"
expect_match "Arial" "Liberation Sans" "Arial stand-in"
expect_match "Times New Roman" "Liberation Serif" "Times New Roman stand-in"
expect_match "Courier New" "Liberation Mono" "Courier New stand-in"
expect_match "Calibri" "Carlito" "Calibri stand-in"
expect_match "Cambria" "Caladea" "Cambria stand-in"
if [ -n "$(fc-list 'STIX Math' family)" ]; then
	pass "STIX Math present (OpenType MATH font for MathML)"
else
	fail "STIX Math missing"
fi

echo "--- Nerd Font icons ---"
expect_cover e702 "Symbols Nerd Font" "devicon git"
expect_cover f418 "Symbols Nerd Font" "octicon git-branch"
if [ -e /etc/fonts/conf.d/10-nerd-font-symbols.conf ]; then
	pass "10-nerd-font-symbols.conf enabled"
else
	fail "/etc/fonts/conf.d/10-nerd-font-symbols.conf missing"
fi

echo "--- generic families ---"
expect_match "monospace" "DejaVu Sans Mono" "monospace unchanged"
info "sans-serif -> $(fc-match sans-serif family) (Noto Sans expected once fonts-noto-core is in; see FONTS.md)"
expect_match "Liberation Mono" "Liberation Mono" "terminator's default font (personalization.tar)"

echo "--- coding fonts ---"
for fam in "Anonymous Pro" "Cascadia Code" "Cascadia Mono" "Fira Code" "Go Mono" "Hack" \
	"JetBrains Mono" "mononoki" "Ubuntu Mono" "Ubuntu Sans Mono"; do
	if [ -n "$(fc-list "$fam" family)" ]; then
		pass "family $fam"
	else
		fail "family $fam missing"
	fi
done

echo
if [ "$fails" -eq 0 ]; then
	echo "all checks passed"
else
	echo "$fails check(s) failed"
	exit 1
fi
