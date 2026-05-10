// =============================================================
// AIM-9 Sidewinder style CANARD fin
// - Double-delta planform (kinked leading edge)
// - Symmetric hexagonal (double-wedge) airfoil
// - No mounting features (add yours later)
// =============================================================
// Coordinate system:
//   X = chordwise  (LE near +X, TE near origin)
//   Y = spanwise   (root at Y=0, tip at +Y)
//   Z = thickness  (symmetric about Z=0)
// =============================================================

/* [Planform] */
root_chord       = 50;     // chord at the root (mm)
tip_chord        = 4;      // small flat at tip (set 1-2mm for sharp tip)
span             = 28;     // root-to-tip distance (mm)

// Double-delta leading edge
kink_span_frac   = 0.45;   // fraction of span where LE sweep changes
inboard_sweep    = 70;     // inboard LE sweep (deg)
outboard_sweep   = 45;     // outboard LE sweep (deg)
trailing_sweep   = 5;      // small forward sweep on TE (deg)

/* [Airfoil - symmetric hexagonal / double-wedge] */
thickness_pct    = 0.07;   // max thickness as fraction of local chord
flat_start_pct   = 0.35;   // chord fraction where flat top begins
flat_end_pct     = 0.55;   // chord fraction where flat top ends

$fn = 64;

// =============================================================
// Planform helpers
// =============================================================
function le_x_at_y(y) =
    y <= span*kink_span_frac
        ? root_chord - y * tan(inboard_sweep)
        : (root_chord - span*kink_span_frac * tan(inboard_sweep))
          - (y - span*kink_span_frac) * tan(outboard_sweep);

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
// =============================================================
module fin() {
    n_stations = 24;
    for (i = [0 : n_stations-1]) {
        y0 = i * span / n_stations;
        y1 = (i+1) * span / n_stations;
        c0 = le_x_at_y(y0) - te_x_at_y(y0);
        c1 = le_x_at_y(y1) - te_x_at_y(y1);
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
