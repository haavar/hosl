#!/bin/zsh
# WORK IN PROGRESS (not test-printed)
# Usage: ./make-gridfinity-rugged.sh GX GY GZ [outdir] [extra -D args...]
# Writes base/lid/latch/handle(/label) STLs for one box size.
# Example: ./make-gridfinity-rugged.sh 4 3 5 out -D 'label=true' -D 'label_text="Screws"'
set -e
OS=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
GX=$1 GY=$2 GZ=$3 OUT=${4:-out}; shift 3; shift || true
mkdir -p "$OUT"
LABEL=${LABEL:-false}; TEXT=${TEXT:-}
tmp=$(mktemp -d)
for part in bottom top latch handle; do
  cat > $tmp/p.scad <<SCAD
include <$PWD/gridfinity-rugged-box.scad>;
grugged($GX, $GY, $GZ, part="$part", label=$LABEL, label_text="$TEXT");
SCAD
  $OS --backend=manifold -o "$OUT/gf-rugged-${GX}x${GY}x${GZ}U-$part.stl" $tmp/p.scad 2>&1 | grep -iE "error" || true
done
rm -rf $tmp; ls "$OUT"
