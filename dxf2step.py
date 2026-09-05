#!/usr/bin/env python3
# SPDX-License-Identifier: CC-BY-SA-4.0
# Copyright (c) 2026 Julian Jakobs

import os
import sys

import cadquery as cq

if len(sys.argv) != 4:
    print("Usage: python3 dxf2step.py <input.dxf> <output.step> <thickness_mm>")
    sys.exit(1)

input_dxf = sys.argv[1]
output_step = sys.argv[2]
thickness = float(sys.argv[3])

try:
    print(f"Importing {input_dxf} and extruding to {thickness}mm...")
    
    # 1. Import DXF
    # 2. Extract wires and bind them into a solid face
    # 3. Extrude to defined thickness
    solid_model = (
        cq.importers.importDXF(input_dxf)
        .wires()
        .toPending()
        .extrude(thickness)
    )
    
    print(f"Exporting solid STEP format to {output_step}...")
    cq.exporters.export(solid_model, output_step)

    # OpenCASCADE's STEP writer reports failure on stdout and returns
    # normally, so an unwritable output directory would otherwise look
    # like a successful build.
    if not os.path.getsize(output_step):
        raise RuntimeError(f"{output_step} was not written")

    print("Success!")
    
except Exception as e:
    print(f"Error during conversion: {e}")
    sys.exit(1)
