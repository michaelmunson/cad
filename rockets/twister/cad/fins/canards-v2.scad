// =============================================================
// Triangular canard fin, servo actuated
// - Simple triangular planform
// - Toothed socket bored into the root edge that presses directly
//   onto the servo's 20-tooth output spline, the same way a horn
//   does: 20 printed ridges mesh with the spline teeth
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
// Toothed socket bored into the root edge along the hinge axis.
// The fin presses onto the servo's output spline like a horn:
// the socket is the negative of the spline, ridges and all.
spline_axis_x   = 30;     // chordwise position of servo shaft axis (mm from TE)
spline_teeth    = 20;     // number of teeth on the servo spline
spline_d        = 4.8;    // spline outer (tooth tip) diameter (mm)
spline_root_d   = 4.2;    // spline root diameter, between teeth (mm)
spline_fit      = 0;      // bore adjustment: negative = tighter press fit (mm)
spline_depth    = 4;      // socket depth = spline engagement length (mm)
tooth_tip_frac  = 0.15;   // tooth tip half-width as fraction of tooth pitch
tooth_base_frac = 0.30;   // tooth base half-width as fraction of tooth pitch

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
// 2D cross-section of the male spline: a root circle with 20
// trapezoidal teeth out to the tip diameter. Subtracting this
// leaves matching ridges inside the socket bore.
// =============================================================
module spline_profile_2d() {
    r_tip  = (spline_d + spline_fit) / 2;
    r_root = (spline_root_d + spline_fit) / 2;
    pitch  = 360 / spline_teeth;
    union() {
        circle(r = r_root, $fn = 64);
        polygon([
            for (i = [0 : spline_teeth - 1],
                 p = [[-tooth_base_frac, r_root],
                      [-tooth_tip_frac,  r_tip],
                      [ tooth_tip_frac,  r_tip],
                      [ tooth_base_frac, r_root]])
                let (a = (i + p[0]) * pitch)
                    [p[1] * cos(a), p[1] * sin(a)]
        ]);
    }
}

// =============================================================
// Spline socket - toothed bore entering the root edge along the
// hinge axis; the servo spline presses in and the ridges key it
// =============================================================
module spline_socket() {
    translate([spline_axis_x, spline_depth, 0])
        rotate([90, 0, 0])
            linear_extrude(height = spline_depth + eps)
                spline_profile_2d();
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
