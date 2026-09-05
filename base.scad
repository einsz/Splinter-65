// SPDX-License-Identifier: CC-BY-SA-4.0
// Copyright (c) 2026 Julian Jakobs

// Splinter 65 - Base Plate, for 0702 motors

// --- Core Parameters ---
render_3d = true;
frame_thickness = 1;
motor_to_motor = 65;
fc_mount_spacing = 25.5;

// --- Motor Mount Specs (0702 3-hole) ---
motor_pcd = 6.6;
motor_screw_hole = 1.5;
motor_center_hole = 3.5;

// --- Design Tuning ---
fc_pad_dia = 4.5;
rear_pad_bonus = 1.0;      // Extra material for the rear (USB) pad
arm_root_width = 3.4;      // At the centre ring - where the moment peaks
arm_tip_width  = 1.4;      // At the motor - where the moment is zero
center_hole_dia = 26;
web_width = 1.8;
internal_brace_width = 1.2;
usb_bulge = 3.0;           // Smooth eccentric arch for USB clearance

// --- Motor Pad Scallops ---
// The pad hub is inert at these values - it sits entirely inside the hull
// of the three lobes and contributes no area. Kept only as a safety net if
// motor_pad_lobe_r is ever dropped below ~1.7, where the lobes stop meeting.
motor_pad_hub_r  = 2.5;
motor_pad_lobe_r = 2.1;    // lobe radius around each motor screw
pad_scallop_r    = 3.5;    // concave cutter radius between lobes; 0 disables

// --- SPLIT FILLET CONTROLS ---
main_fillet_radius = 2.5;  // Large fillets for main motor arms
strut_fillet_radius = 1.0; // Tighter fillets for FC struts and brace

$fn = 128;

// --- Calculated Geometry ---
// Each scallop cutter is placed tangent to the two lobes it lies between,
// so it eats only the web and never touches the bolt circle - minimum screw
// edge distance stays at motor_pad_lobe_r - hole/2 = 1.45mm, exactly as it
// was with the plain hull.
pad_a = motor_pcd / 2;
pad_scallop_d = (pad_a + sqrt(4*pow(pad_scallop_r + motor_pad_lobe_r, 2) - 3*pow(pad_a, 2))) / 2;

fc_radius = fc_mount_spacing / sqrt(2); // ~18.03mm

module bulging_circle(r, bulge) {
    union() {
        // Left half (original circle)
        difference() {
            circle(r=r);
            translate([0, -r-1]) square([r+bulge+1, 2*r+2]);
        }
        // Right half (scaled circle into an ellipse to create the arch)
        difference() {
            scale([(r+bulge)/r, 1]) circle(r=r);
            translate([- (r+bulge) - 1, -r-1]) square([r+bulge+1, 2*r+2]);
        }
    }
}

module core_ring() {
    bulging_circle(center_hole_dia/2 + web_width, usb_bulge);
}

module core_hole() {
    bulging_circle(center_hole_dia/2, usb_bulge);
}

module motor_arms() {
    for(i=[45, 135, 225, 315]) {
        rotate([0, 0, i]) {
            // Tapered arm: full width at the root, minimum at the motor
            hull() {
                translate([center_hole_dia/2, 0]) circle(d=arm_root_width);
                translate([motor_to_motor/2, 0])  circle(d=arm_tip_width);
            }

            translate([motor_to_motor/2, 0]) {
                hull() {
                    circle(r=motor_pad_hub_r);
                    for(j=[0, 120, 240]) {
                        rotate([0, 0, j])
                            translate([motor_pcd/2, 0])
                            circle(r=motor_pad_lobe_r);
                    }
                }
            }
        }
    }
}

module fc_struts() {
    for(i=[0, 90, 180, 270]) {
        rotate([0, 0, i]) {
            hull() {
                translate([center_hole_dia/2, 0]) circle(d=web_width*2);
                // Extra material on the rear pad so it survives the offset
                translate([fc_radius, 0]) circle(d= (i == 0) ? fc_pad_dia + rear_pad_bonus : fc_pad_dia);
            }
        }
    }
}

module internal_brace() {
    for(i=[45, 135]) {
        rotate([0, 0, i])
            translate([-(center_hole_dia + usb_bulge)/2, -internal_brace_width/2])
                square([center_hole_dia + usb_bulge, internal_brace_width]);
    }
}

module frame_2d() {
    difference() {
        union() {
            // --- GROUP 1: Motor Arms (Heavy Fillets) ---
            offset(r=-main_fillet_radius) {
                offset(r=main_fillet_radius) {
                    difference() {
                        union() {
                            core_ring();
                            motor_arms();
                        }
                        core_hole(); // Hollow centre BEFORE offset
                    }
                }
            }

            // --- GROUP 2: FC Struts & Internal Brace (Tight Fillets) ---
            offset(r=-strut_fillet_radius) {
                offset(r=strut_fillet_radius) {
                    union() {
                        difference() {
                            union() {
                                core_ring();
                                fc_struts();
                            }
                            core_hole(); // Hollow centre BEFORE offset
                        }
                        // Add internal brace BACK IN across the hollowed space
                        internal_brace();
                    }
                }
            }
        }

        // --- 2. Subtractions (Holes & Cutouts) ---

        // FC Mounting Holes (Diamond pattern)
        for(i=[0, 90, 180, 270]) {
            rotate([0, 0, i]) {
                translate([fc_radius, 0])
                    circle(d=2.05, $fn=32);
            }
        }

        // Motor Mounting Holes
        for(i=[45, 135, 225, 315]) {
            rotate([0, 0, i]) {
                translate([motor_to_motor/2, 0]) {
                    circle(d=motor_center_hole);
                    for(j=[0, 120, 240]) {
                        rotate([0, 0, j])
                            translate([motor_pcd/2, 0])
                            circle(d=motor_screw_hole, $fn=16);
                    }

                    // Concave scallops between the lobes.
                    //
                    // Cut HERE, in the final difference, not in the pad hull:
                    // the main_fillet closing operation (offset +r then -r)
                    // fills any concave notch tighter than its radius, so a
                    // scallop added upstream would simply be erased.
                    //
                    // Only the two side gaps are cut. The third gap, at 180
                    // deg, is where the arm lands, and a cutter there would
                    // sever it.
                    if (pad_scallop_r > 0) {
                        for(j=[60, -60]) {
                            rotate([0, 0, j])
                                translate([pad_scallop_d, 0])
                                circle(r=pad_scallop_r);
                        }
                    }
                }
            }
        }
    }
}

if (render_3d) {
    linear_extrude(height=frame_thickness) {
        frame_2d();
    }
} else {
    frame_2d();
}
