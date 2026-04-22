#!/usr/bin/env bash
# Generate a 1280x800 vaporwave wallpaper (sun + grid) using ImageMagick.
# Run once on the build host; output is copied into the ISO by build.sh.
set -euo pipefail

OUT="$(dirname "$0")/../airootfs/usr/share/backgrounds/vaporwave/sunset.png"
mkdir -p "$(dirname "$OUT")"

command -v magick &>/dev/null || { echo "ImageMagick not installed"; exit 1; }

# Base: vertical gradient sky (deep purple → hot pink → orange)
magick -size 1280x800 \
    gradient:"#1a0933-#ff71ce" \
    \( -size 1280x400 gradient:"#ff71ce-#ffb86c" \) -geometry +0+200 -composite \
    \
    \( -size 600x600 radial-gradient:"#fffb96-#ff3caf" \
       -alpha set -channel A -evaluate multiply 0.9 +channel \
    \) -geometry +340+80 -composite \
    \
    \( -size 1280x400 xc:none \
       -fill none -stroke "#01cdfe" -strokewidth 2 \
       $(for i in $(seq 0 40 1280); do echo -draw "line $i,0 $((i-200)),400"; done) \
       $(for i in $(seq 0 30 400); do echo -draw "line 0,$i 1280,$i"; done) \
       -alpha set -channel A -evaluate multiply 0.7 +channel \
    \) -geometry +0+420 -composite \
    \
    -font DejaVu-Sans-Bold -pointsize 42 -fill "#ffffff" \
    -gravity center -annotate +0-200 "ＡＥＳＴＨＥＴＩＣ" \
    \
    "$OUT"

echo "Wallpaper written to $OUT"
