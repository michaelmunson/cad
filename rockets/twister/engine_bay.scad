/*
 * Twister mk2 — engine bay (lightweight)
 *
 * Inner engine tube + thin outer shell joined by radial ribs (no solid annulus).
 * ~80% of height is coupler (OD mid band + shoulder into fuselage); ~20% is
 * the short engine sleeve below — motor bore runs full height through both.
 * Open engine sleeve at top; 2 mm bottom plate seals annulus for ejection pressure.
 * Four bolt holes through ribs + mid-band shell.
 *
 * Print: nozzle end down; ribs along Z need no infill in a solid block.
 */

// ----- Body tube (caliper your stock)
body_tube_od = 79.2;       // mm, nominal outer diameter
body_tube_id = 76.2;       // mm, nominal inner diameter
clearance = 0;             // mm subtracted from ID for shoulder OD (diameter slack)

// ----- Engine (model rocket motor)
engine_d = 29;             // mm, motor case OD
engine_len = 83;           // mm, motor case length

// ----- Height split (outer profile; inner motor tube is full height)
coupler_fraction = 0.8;    // coupler (mid band + shoulder) as share of total_h
shoulder_coupler_len = 68;  // mm, glue overlap into fuselage bore
engine_sleeve_extra = 5;   // mm beyond motor length (nozzle / retention slack)
motor_bore_min_len = engine_len + engine_sleeve_extra;
total_h = motor_bore_min_len;
coupler_len = coupler_fraction * total_h;
engine_sleeve_len = total_h - coupler_len;
mid_band_len = coupler_len - shoulder_coupler_len;

// ----- Engine bore slack
engine_clearance = 0.4;    // mm added to motor OD for slip fit

// ----- Thin shells + ribs (print ≥1.2 mm walls on your printer)
inner_wall_t = 1.6;        // mm, engine tube wall
outer_wall_t = 1.6;        // mm, fuselage shell wall
rib_count = 4;             // radial spokes; aligns with bolt pattern
rib_width = 2.5;           // mm, tangential width of each rib at mid span
bottom_plate_t = 2;        // mm, seals annulus between inner/outer tubes at nozzle end

// ----- Fuselage retention (four bolts, 0/90/180/270°)
bolt_hole_d = 3.2;         // mm, M3 clearance; enlarge if binding in plastic
bolt_hole_z_offset = 0;    // mm along Z from mid of coupler+mid band; 0 = centered

// ----- Tessellation
$fn = 64;

// ----- Derived
shoulder_outer_r = (body_tube_id - clearance) / 2;
middle_outer_r = body_tube_od / 2;
engine_inner_r = (engine_d + engine_clearance) / 2;
inner_tube_outer_r = engine_inner_r + inner_wall_t;
bolt_z_center = engine_sleeve_len + mid_band_len / 2 + bolt_hole_z_offset;
mount_r_mid = (inner_tube_outer_r + middle_outer_r - outer_wall_t) / 2;
shoulder_shell_inner_r = shoulder_outer_r - outer_wall_t;
mid_shell_inner_r = middle_outer_r - outer_wall_t;

assert(mid_band_len > 0,
       "Increase total_h or coupler_fraction — shoulder longer than coupler_len");
assert(rib_count >= 3, "Need at least three ribs for stability");
assert(inner_wall_t >= 1.2 && outer_wall_t >= 1.2, "Walls below 1.2 mm may not print reliably");
assert(mid_shell_inner_r > inner_tube_outer_r + 1,
       "Inner tube and outer shell overlap — increase body_tube_od or reduce engine_d");

module tube(h, r_inner, r_outer) {
  difference() {
    cylinder(h = h, r = r_outer);
    translate([0, 0, -0.01])
      cylinder(h = h + 0.02, r = r_inner);
  }
}

module inner_engine_tube() {
  tube(total_h, engine_inner_r, inner_tube_outer_r);
}

// Outer shell: full OD sleeve + shoulder coupler (thin wall only).
module outer_shell() {
  tube(engine_sleeve_len + mid_band_len, mid_shell_inner_r, middle_outer_r);
  translate([0, 0, engine_sleeve_len + mid_band_len])
    tube(shoulder_coupler_len, shoulder_shell_inner_r, shoulder_outer_r);
}

module rib_spokes(z0, z1, r_outer_attach) {
  rib_len = r_outer_attach - inner_tube_outer_r;
  for (a = [0 : 360 / rib_count : 360 - 360 / rib_count])
    rotate([0, 0, a])
      translate([inner_tube_outer_r, -rib_width / 2, z0])
        cube([rib_len, rib_width, z1 - z0]);
}

// Solid annulus at nozzle end — closes rib gaps so ejection charge pressurizes the tube.
module bottom_pressure_plate() {
  tube(bottom_plate_t, inner_tube_outer_r, mid_shell_inner_r);
}

module fuselage_bolt_holes() {
  for (a = [0 : 90 : 270])
    rotate([0, 0, a])
      translate([mount_r_mid, 0, bolt_z_center])
        rotate([0, 90, 0])
          cylinder(h = outer_wall_t + rib_width + 2, d = bolt_hole_d, center = true);
}

difference() {
  union() {
    inner_engine_tube();
    outer_shell();
    bottom_pressure_plate();
    rib_spokes(0, engine_sleeve_len + mid_band_len, mid_shell_inner_r);
    rib_spokes(engine_sleeve_len + mid_band_len, total_h, shoulder_shell_inner_r);
  }
  fuselage_bolt_holes();
}
