/*
 * Twister mk2 — engine bay
 *
 * Stepped OD: coupler shoulder slips inside the body tube bore (ID − clearance);
 * the mid band is flush with the outside (OD) at the fuselage bottom joint.
 * Open engine sleeve (both ends) for a 29 mm × 83 mm motor; four radial bolt
 * holes in the coupler/mid band for fuselage retention.
 *
 * Print: standing on the open engine end (nozzle down); supports only if needed
 * inside the engine bore.
 */

// ----- Body tube (caliper your stock)
body_tube_od = 79.2;       // mm, nominal outer diameter
body_tube_id = 76.2;       // mm, nominal inner diameter
clearance = 0;             // mm subtracted from ID for shoulder OD (diameter slack)

// ----- Engine (model rocket motor)
engine_d = 29;             // mm, motor case OD
engine_len = 83;           // mm, motor case length

// ----- Shoulder / bands
shoulder_coupler_len = 7;  // mm, glue overlap into fuselage bore
mid_band_len = 12;         // mm, OD flush with tube; bolt holes land here
engine_sleeve_extra = 5;   // mm beyond motor length (nozzle / retention slack)
engine_sleeve_len = engine_len + engine_sleeve_extra;

// ----- Engine bore slack
engine_clearance = 0.4;    // mm added to motor OD for slip fit

// ----- Wall (mid band; engine sleeve uses full OD shell)
wall_thickness = 3.1;      // mm radial shell in mid band (room for bolt through wall)

// ----- Fuselage retention (four bolts, 0/90/180/270°)
bolt_hole_d = 3.2;         // mm, M3 clearance; enlarge if binding in plastic
bolt_hole_z_offset = 0;    // mm along Z from mid of coupler+mid band; 0 = centered

// ----- Tessellation
$fn = 64;

// ----- Derived
shoulder_outer_r = (body_tube_id - clearance) / 2;
middle_outer_r = body_tube_od / 2;
engine_inner_r = (engine_d + engine_clearance) / 2;
total_h = engine_sleeve_len + mid_band_len + shoulder_coupler_len;
coupler_z0 = engine_sleeve_len;
coupler_z1 = engine_sleeve_len + mid_band_len;
bolt_z_center = (coupler_z0 + coupler_z1) / 2 + bolt_hole_z_offset;
mount_r_mid = (engine_inner_r + middle_outer_r) / 2;
outer_mount_keep = 3;      // mm OD strip left for bolt bearing (like servo_bay)

assert(middle_outer_r - engine_inner_r >= wall_thickness,
       "Fuselage OD too small for engine bore + wall_thickness");
assert(outer_mount_keep > 0 && outer_mount_keep < wall_thickness,
       "outer_mount_keep must leave an OD strip thinner than full wall but non-zero");

module coupler_solid() {
  union() {
    cylinder(h = engine_sleeve_len, r = middle_outer_r);
    translate([0, 0, engine_sleeve_len])
      cylinder(h = mid_band_len, r = middle_outer_r);
    translate([0, 0, engine_sleeve_len + mid_band_len])
      cylinder(h = shoulder_coupler_len, r = shoulder_outer_r);
  }
}

module engine_bore() {
  translate([0, 0, -0.01])
    cylinder(h = total_h + 0.02, r = engine_inner_r);
}

module fuselage_bolt_holes() {
  for (a = [0 : 90 : 270])
    rotate([0, 0, a])
      translate([mount_r_mid, 0, bolt_z_center])
        rotate([0, 90, 0])
          cylinder(h = outer_mount_keep + 6, d = bolt_hole_d, center = true);
}

difference() {
  coupler_solid();
  engine_bore();
  fuselage_bolt_holes();
}
