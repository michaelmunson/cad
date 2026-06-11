// =============================================================
// Triangular canard fin, servo actuated
// - Simple triangular planform
// - Round socket bored into the root edge that presses directly
//   onto the servo's 20-tooth output spline, the same way a horn
//   does: the teeth bite into the printed bore for the grip
// =============================================================
// Coordinate system:
//   X = chordwise  (LE at +X, TE at X=0)
//   Y = spanwise   (root at Y=0, tip at +Y)
//   Z = thickness  (symmetric about Z=0)
// =============================================================

/* [Planform] */
fin_height    = 75;    // root-to-tip span (mm)
fin_width     = 100;     // root chord (mm)
tip_offset    = 0;     // X position of the tip point (mm from TE)
fin_thickness = 4;      // overall fin thickness (mm)

/* [Servo spline socket] */
// Round socket bored into the root edge along the hinge axis.
// The fin presses onto the servo's output spline like a horn:
// the 20 teeth cut into the printed bore and key the fin.
spline_axis_x   = 30;     // chordwise position of servo shaft axis (mm from TE)
spline_d        = 4.8;    // 20-tooth spline outer diameter (mm)
spline_fit      = 0;      // bore adjustment: negative = tighter press fit (mm)
spline_depth    = 4;      // socket depth = spline engagement length (mm)

/* [Spline boss] */
// The 4.8 mm socket is wider than the fin is thick, so a round
// boss (like a horn hub) reinforces the bore at the root edge.
boss_d          = 9;      // boss outer diameter (mm)
boss_length     = 6;      // boss length up from the root edge (mm)

$fn = 32;
eps = 0.01;

// =============================================================
// Triangular planform (2D, XY plane)
// =============================================================
module fin_planform_2d() {
    polygon([
        [0, 0],              // trailing edge, root
        [fin_width, 0],      // leading edge, root
        [tip_offset, fin_height]  // tip
    ]);
}

// =============================================================
// Spline boss - hub-like cylinder on the hinge axis at the root
// edge, thick enough to wrap the spline socket on all sides
// =============================================================
module spline_boss() {
    translate([spline_axis_x, 0, 0])
        rotate([-90, 0, 0])
            cylinder(d = boss_d, h = boss_length);
}

// =============================================================
// Spline socket - round bore entering the root edge along the
// hinge axis; presses onto the 20-tooth servo spline
// =============================================================
module spline_socket() {
    translate([spline_axis_x, -eps, 0])
        rotate([-90, 0, 0])
            cylinder(d = spline_d + spline_fit, h = spline_depth + eps, $fn = 64);
}

// =============================================================
// Canard fin
// =============================================================
module canard() {
    difference() {
        union() {
            linear_extrude(height = fin_thickness, center = true)
                fin_planform_2d();
            spline_boss();
        }
        spline_socket();
    }
}

// =============================================================
// Render
// =============================================================
canard();
