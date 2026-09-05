// SPDX-License-Identifier: CC-BY-SA-4.0
// Copyright (c) 2026 Julian Jakobs

// Splinter 65 - Prop Guard Top Plate

// --- Core Parameters ---
render_3d = true;
plate_thickness = 1.5;
motor_to_motor = 65;
fc_mount_spacing = 25.5;

// --- Prop Guard Specs ---
prop_dia = 31.0;           // Fits standard 31mm (1.2") props
prop_clearance = 1;        // Safety gap around the prop to prevent strikes
web_width = 1.45;          // Base structural width

// --- Tie geometry ---
// tie_radius is the main structural/aesthetic knob:
tie_radius = 39;
strut_width = 1.35;         // tie width
tie_sweep = 4.5;           // gentle inward waist

// --- Eccentric Ring Modifiers ---
// Adjust ring width relative to web_width, around the ring.
outer_tip_bonus = 0.45;    // outer tip 1.9mm - the impact point
side_bonus = 0.3;          // shoulder  1.75mm
inner_tip_reduction = 0.45;// inner tip 1.0mm

// --- FC / standoff mount ---
fc_pad_dia = 4.3;
fc_hole_dia = 2.05;
spoke_width = 1.15;        // explicit pad-to-ring spokes, see fc_mounts()
inner_fillet_radius = 2.0;
outer_fillet_radius = 1;

$fn = 128;

// --- Calculated Geometry ---
ring_id = prop_dia + (prop_clearance * 2);
r_in = ring_id / 2;
fc_radius = fc_mount_spacing / sqrt(2);
motor_radius = motor_to_motor / 2;

// --- Eccentric Ellipse Math ---
rx = r_in + web_width + (outer_tip_bonus - inner_tip_reduction) / 2;
e_shift = (outer_tip_bonus + inner_tip_reduction) / 2;
ry = r_in + web_width + side_bonus;

// Radial position of each ring ellipse centre (needed by the spokes)
ring_c_r = motor_radius + e_shift;

cy = motor_radius * sin(45);

// --- Geometry Modules ---

module guard_rings() {
    for(i=[45, 135, 225, 315]) {
        rotate([0, 0, i])
            translate([motor_radius, 0])
                translate([e_shift, 0]) // Shift the ellipse outward
                    scale([rx, ry])     // Apply eccentric scaling
                        circle(r=1);
    }
}

module fc_mounts() {
    for(i=[0, 90, 180, 270]) {
        rotate([0, 0, i]) {
            // Standoff pad
            translate([fc_radius, 0]) circle(d=fc_pad_dia);

            // EXPLICIT spokes to the two neighbouring rings.
            for(k = [45, -45]) {
                hull() {
                    translate([fc_radius, 0]) circle(d=spoke_width);
                    translate([ring_c_r * cos(k), ring_c_r * sin(k)])
                        circle(d=spoke_width);
                }
            }
        }
    }
}

module outer_support_struts() {
    // Tie pulled inboard to tie_radius. The endpoints sit at +/-cy, deep
    // inside the ring ellipses, so the union is guaranteed; the prop
    // cutouts then trim the tie back to the gap between the two props.
    for(i=[0, 90, 180, 270]) {
        rotate([0, 0, i]) {
            for(j=[0:19]) {
                hull() {
                    translate([tie_radius - tie_sweep * pow(1 - pow(-1 + 2*(j/20), 2), 2),
                               cy * (-1 + 2*(j/20))]) circle(d=strut_width);
                    translate([tie_radius - tie_sweep * pow(1 - pow(-1 + 2*((j+1)/20), 2), 2),
                               cy * (-1 + 2*((j+1)/20))]) circle(d=strut_width);
                }
            }
        }
    }
}

module top_plate_2d() {
    difference() {

        // --- 1. Blended Solid Base ---
        union() {
            // INNER GROUP: fillets for the standoff pads and spokes
            offset(r=-inner_fillet_radius) {
                offset(r=inner_fillet_radius) {
                    union() {
                        guard_rings();
                        fc_mounts();
                    }
                }
            }

            // OUTER GROUP: tight fillets for the ties
            offset(r=-outer_fillet_radius) {
                offset(r=outer_fillet_radius) {
                    union() {
                        guard_rings();
                        outer_support_struts();
                    }
                }
            }
        }

        // --- 2. Subtractions ---

        // Propeller cutouts (clean circles, cut after all offsets).
        // These are also what trims the ties to length.
        for(i=[45, 135, 225, 315]) {
            rotate([0, 0, i])
                translate([motor_radius, 0])
                    circle(d=ring_id);
        }

        // Standoff holes (diamond orientation)
        for(i=[0, 90, 180, 270]) {
            rotate([0, 0, i])
                translate([fc_radius, 0])
                    circle(d=fc_hole_dia, $fn=32);
        }
    }
}

// Extrude into 3D
if (render_3d) {
    linear_extrude(height=plate_thickness) {
        top_plate_2d();
    }
} else {
    top_plate_2d();
}
