// =============================================================
// AIM-9 Sidewinder style REAR fin (wing)
// - Clipped delta / trapezoidal planform
// - ~60deg swept leading edge
// - Near-perpendicular trailing edge
// - Symmetric hexagonal (double-wedge) airfoil
// - No mounting features (add yours later)
// =============================================================
// Coordinate system:
//   X = chordwise  (LE near +X, TE near origin)
//   Y = spanwise   (root at Y=0, tip at +Y)
//   Z = thickness  (symmetric about Z=0)
// =============================================================

/* [Planform] */
root_chord       = 80;     // chord at the root (mm)
tip_chord        = 35;     // chord at the tip - clipped, not pointed (mm)
span             = 45;     // root-to-tip distance (mm)

leading_sweep    = 60;     // LE sweep angle (deg)
trailing_sweep   = 3;      // small forward sweep on TE (deg, 0 = square)

/* [Airfoil - symmetric hexagonal / double-wedge] */
thickness_pct    = 0.06;   // max thickness as fraction of local chord
flat_start_pct   = 0.35;   // chord fraction where flat top begins
flat_end_pct     = 0.55;   // chord fraction where flat top ends

$fn = 64;

// =============================================================
// Planform helpers
// =============================================================
// Single sweep angle on the leading edge - simple delta
function le_x_at_y(y) = root_chord - y * tan(leading_sweep);

// Trailing edge - mostly perpendicular to root
function te_x_at_y(y) = 0 + y * tan(trailing_sweep);

// =============================================================
// Hexagonal airfoil cross-section
// =============================================================
module hex_airfoil_2d(c) {
    t = c * thickness_pct;
    x1 = c * flat_start_pct;
    x2 = c * flat_end_pct;
    polygon([
        [0,   0],
        [x1,  t/2],
        [x2,  t/2],
        [c,   0],
        [x2, -t/2],
        [x1, -t/2]
    ]);
}

// =============================================================
// Fin solid - stack airfoils along span and hull adjacent ones
//
// For a clipped tip, we clamp the leading edge so the local chord
// at the tip is at least tip_chord. This naturally produces the
// trapezoidal shape: pure delta until the tip is reached, then
// a flat tip edge.
// =============================================================
module fin() {
    n_stations = 32;

    // Local chord at spanwise position y, with tip clipping
    function local_chord(y) =
        let(le = le_x_at_y(y), te = te_x_at_y(y))
            max(le - te, tip_chord);

    // For the LE position with clipping: when natural LE would
    // give chord < tip_chord, push LE forward to maintain tip_chord
    function le_x_clipped(y) =
        let(natural_le = le_x_at_y(y), te = te_x_at_y(y))
            max(natural_le, te + tip_chord);

    for (i = [0 : n_stations-1]) {
        y0 = i * span / n_stations;
        y1 = (i+1) * span / n_stations;
        c0 = local_chord(y0);
        c1 = local_chord(y1);
        x0 = te_x_at_y(y0);
        x1 = te_x_at_y(y1);
        if (c0 > 0.5 && c1 > 0.5) {
            hull() {
                translate([x0, y0, 0])
                    rotate([90, 0, 0])
                        linear_extrude(height = 0.01)
                            hex_airfoil_2d(c0);
                translate([x1, y1 - 0.01, 0])
                    rotate([90, 0, 0])
                        linear_extrude(height = 0.01)
                            hex_airfoil_2d(c1);
            }
        }
    }
}

// =============================================================
// Render
// =============================================================
fin();
