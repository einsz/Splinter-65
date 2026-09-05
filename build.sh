#!/usr/bin/env bash
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright (c) 2026 Julian Jakobs

# Build DXF (2D cut files) and STEP (solids) for both plates into ./output.
#
#   ./build.sh          build both
#   ./build.sh base     build one part
#
# Needs openscad on PATH. STEP conversion runs cadquery in Docker, so the
# host needs Docker but not a working cadquery install. Set STEP=0 to skip
# it and produce DXFs only.

set -euo pipefail

OUT=output
STEP=${STEP:-1}

# part : scad file : thickness in mm
PARTS=(
    "base:base.scad:1.0"
    "guard:guard.scad:1.5"
)

want=${1:-all}
mkdir -p "$OUT"

for entry in "${PARTS[@]}"; do
    IFS=: read -r name scad thickness <<< "$entry"
    [[ $want == all || $want == "$name" ]] || continue

    echo "==> $name  ($scad, ${thickness}mm)"

    rm -f "$OUT/$name.dxf"
    openscad -D "render_3d=false" -o "$OUT/$name.dxf" "$scad"

    if [[ $STEP == 1 ]]; then
        rm -f "$OUT/$name.step"
        # Run as the host user. The image defaults to uid 1000, which cannot
        # write into $OUT when the checkout is owned by another uid (CI).
        docker run --rm --user "$(id -u):$(id -g)" \
            -v "$PWD:/workspace" -w /workspace \
            cadquery/cadquery \
            python3 dxf2step.py "$OUT/$name.dxf" "$OUT/$name.step" "$thickness"
    fi
done

echo "==> done"
ls -la "$OUT"
