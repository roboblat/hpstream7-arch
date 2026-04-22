#!/usr/bin/env bash
# Generate a 1280x800 vaporwave wallpaper using ImageMagick 7.
# Run once on the build host; output is copied into the ISO by build.sh.
set -euo pipefail

OUT="$(dirname "$0")/../airootfs/usr/share/backgrounds/vaporwave/sunset.png"
mkdir -p "$(dirname "$OUT")"

command -v magick &>/dev/null || { echo "ImageMagick not installed"; exit 1; }

# Build the grid lines as a separate argument list (IM7 is strict about
# how -draw primitives are passed — each -draw takes a single string).
GRID_DRAWS=()
GRID_DRAWS+=( -stroke "#01cdfe" -strokewidth 2 -fill none )
for x in $(seq -200 40 1480); do
    x2=$((x - 200))
    GRID_DRAWS+=( -draw "line $x,0 $x2,400" )
done
for y in $(seq 0 30 400); do
    GRID_DRAWS+=( -draw "line 0,$y 1280,$y" )
done

# ── 1. sky gradient (purple → pink → orange) ────────────────────────────
magick -size 1280x800 gradient:"#1a0933-#ff71ce" /tmp/sky.png
magick -size 1280x400 gradient:"#ff71ce-#ffb86c" /tmp/horizon.png
magick /tmp/sky.png /tmp/horizon.png -geometry +0+400 -composite /tmp/base.png

# ── 2. neon sun ─────────────────────────────────────────────────────────
magick -size 600x600 radial-gradient:"#fffb96-#ff3caf" \
    -alpha set -channel A -evaluate multiply 0.9 +channel /tmp/sun.png
magick /tmp/base.png /tmp/sun.png -geometry +340+80 -composite /tmp/base.png

# ── 3. perspective grid ─────────────────────────────────────────────────
magick -size 1280x400 xc:none "${GRID_DRAWS[@]}" \
    -alpha set -channel A -evaluate multiply 0.7 +channel /tmp/grid.png
magick /tmp/base.png /tmp/grid.png -geometry +0+420 -composite /tmp/base.png

# ── 4. title text ──────────────────────────────────────────────────────
magick /tmp/base.png \
    -pointsize 42 -fill "#ffffff" -gravity center \
    -annotate +0-200 "AESTHETIC" \
    "$OUT"

rm -f /tmp/sky.png /tmp/horizon.png /tmp/base.png /tmp/sun.png /tmp/grid.png
echo "Wallpaper written to $OUT"
