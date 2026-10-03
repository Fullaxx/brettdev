#!/bin/bash
#
# make_doc_images.sh - regenerate docs/fonts/*.png from the fonts installed now.
#
# Usage: tests/fonts/make_doc_images.sh [OUTDIR]      (default: docs/fonts in the repo)
#   claude-glyphs.png  Claude Code's UI glyphs: the image's original fonts vs now
#   coding-fonts.png   every coding font, as terminator (VTE) draws it
#   ligatures.png      the ligature fonts in VTE vs GTK
#   icons.png          Powerline and Nerd Font icons, without vs with Symbols Nerd Font
#
# Run it where scripts/add_fonts.sh has been applied. If Anonymous Pro isn't
# installed, it's fetched with debs.py and added through fcconf.sh.
# Needs /usr/bin/python3 with GTK 3 and VTE 2.91, and a DISPLAY. If `python3` has
# Pillow, the PNGs are also shrunk.

set -e
here=$(cd "$(dirname "$0")" && pwd)
out=${1:-$(cd "$here/../.." && pwd)/docs/fonts}
export FONTTEST_WORK=${FONTTEST_WORK:-${TMPDIR:-/tmp}/fonttest}
img=$FONTTEST_WORK/img
mkdir -p "$out" "$img"

# Font directories of the families the image had before add_fonts.sh existed
old_dirs=()
for fam in "DejaVu Sans Mono" "DejaVu Sans" "Liberation Mono" "Liberation Sans" "OpenSymbol" "Nimbus Sans"; do
	file=$(fc-list "$fam" file | head -1 | cut -d: -f1)
	[ -n "$file" ] && old_dirs+=("$(dirname "$file")")
done
mapfile -t old_dirs < <(printf '%s\n' "${old_dirs[@]}" | sort -u)

echo "== claude-glyphs.png =="
"$here/fcconf.sh" --no-system "${old_dirs[@]}" -- \
	"$here/vte_render.py" --label "Before: the image's original fonts" --out "$img/before.png"
"$here/vte_render.py" --label "After: scripts/add_fonts.sh" --out "$img/after.png"
"$here/specimen.py" stack --out "$out/claude-glyphs.png" "$img/before.png" "$img/after.png"

echo "== coding-fonts.png =="
extra=()
if [ -z "$(fc-list 'Anonymous Pro' family)" ]; then
	"$here/debs.py" fetch fonts-anonymous-pro
	extra=("$FONTTEST_WORK/fonts/fonts-anonymous-pro")
fi
"$here/fcconf.sh" "${extra[@]}" -- "$here/specimen.py" fonts --out "$out/coding-fonts.png"

echo "== ligatures.png =="
"$here/specimen.py" ligatures --out "$out/ligatures.png"

echo "== icons.png =="
"$here/fcconf.sh" --reject '/usr/local/share/fonts/nerd-fonts-symbols/*' -- \
	"$here/specimen.py" icons --title "Without Symbols Nerd Font" --out "$img/icons-before.png"
"$here/specimen.py" icons --title "With Symbols Nerd Font (scripts/add_fonts.sh)" --out "$img/icons-after.png"
"$here/specimen.py" stack --out "$out/icons.png" "$img/icons-before.png" "$img/icons-after.png"

if python3 -c 'import PIL' 2>/dev/null; then
	python3 - "$out"/*.png <<'EOF'
import sys
from PIL import Image
for path in sys.argv[1:]:
    Image.open(path).convert("RGB").quantize(colors=128, method=Image.Quantize.MEDIANCUT).save(path, optimize=True)
EOF
fi
ls -l "$out"/*.png
