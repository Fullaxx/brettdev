#!/bin/bash
#
# script_coverage.sh - which installed font draws each writing system?
# This is what a browser falls back to on a page in that script: Chrome and Firefox
# bundle no text fonts on Linux and ask fontconfig for one.
#
# Usage: tests/fonts/script_coverage.sh [--missing]
#   --missing   only print scripts that no font covers (they would render as tofu)
#
# Found on 2026-10-03:
#   - After fonts-noto-core, every script here rendered except CJK
#     (Han, Hiragana, Katakana, Hangul).
#   - fonts-noto-cjk fills that gap.
#   - Before fonts-noto-core, most non-Latin scripts beyond DejaVu's coverage
#     were missing too.

only_missing=
[ "$1" = "--missing" ] && only_missing=1
missing=0
while read -r cp name; do
	[ -z "$cp" ] && continue
	fams=$(fc-list ":charset=$cp" family | sort -u | head -3 | tr '\n' ';' | sed 's/;$//')
	if [ -z "$fams" ]; then
		missing=$((missing + 1))
		printf '  U+%-6s %-22s *** no font: tofu ***\n' "$cp" "$name"
	elif [ -z "$only_missing" ]; then
		printf '  U+%-6s %-22s %s\n' "$cp" "$name" "$fams"
	fi
done <<'EOF'
4E2D Han (Chinese 中)
3042 Hiragana
30A2 Katakana
AC00 Hangul
0627 Arabic
05D0 Hebrew
0915 Devanagari
0995 Bengali
0B95 Tamil
0C15 Telugu
0E01 Thai
0E81 Lao
1780 Khmer
1000 Myanmar
10D0 Georgian
0531 Armenian
1200 Ethiopic
0D9A Sinhala
0F40 Tibetan
1820 Mongolian
A000 Yi
13A0 Cherokee
1401 Canadian Syllabics
0710 Syriac
0780 Thaana
07CA NKo
2D30 Tifinagh
A984 Javanese
1B05 Balinese
1D11E Musical symbols
1D400 Math alphanumerics
13000 Egyptian hieroglyphs
EOF
echo "$missing script(s) with no font"
