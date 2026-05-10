/*
 * Twister mk1 — BT-80 SG90 servo coupler
 *
 * Stepped OD: upper/lower shoulders slip inside the body tube bore (ID − clearance);
 * the mid band is flush with the outside (OD) at the joint.
 * Four SG90 servos vertical: case long axis || rocket Z; two 2 mm M2 through-holes
 * above and below the output spline (along Z) per servo for mounting.
 *
 * Print: typically standing on a shoulder end with supports on pockets/holes, or
 * split along a plane through the axis if your printer cannot clear overhangs inside
 * the bore (add alignment pins / glue faces in a derived design if needed).
 */

// ----- Body tube (caliper your stock)
body_tube_od = 76.2;       // mm, nominal BT-80 outer diameter (3.00 in) — mid band flush outside
body_tube_id = 74.0;       // mm, nominal BT-80 inner diameter — shoulder OD slip fit
clearance = 0.35;          // mm subtracted from ID for shoulder OD (diameter slack)

// ----- Shoulder lengths (glue overlap into each fuselage segment)
shoulder_bot_len = 35;
shoulder_top_len = 35;

// ----- Servo band (must clear pocket height along Z — see sg90_body_z below)
mid_band_len = 40;

// ----- Wall / bore (bore sized from mid-band OD so the thick ring has full wall)
wall_thickness = 5;      // radial shell thickness in the mid band (room for M2 through wall)

// ----- Servo orientation vs world +X (fin alignment offset)
servo_azimuth_offset = 0; // degrees added to 0/90/180/270 placements

// ----- SG90 case (mm), measured — vertical = long axis || rocket Z
// Given sizes: 12.5 wide × 22.8 tall × 22.4 long → mounted vertically:
//   along rocket Z (coupler axis): 22.4 mm (case “long”)
//   tangential (side to side around tube): 12.5 mm (case “wide”)
//   radial (into bore from mounting face): 22.8 mm (case “tall”)
sg90_case_z = 22.4;
sg90_case_w = 12.5;
sg90_case_radial = 22.8;

// M2 ear spacing along the mounting axis (SG90 tabs are farther apart than 22.4 mm case length).
sg90_hole_spacing = 28;

m2_mount_hole_spacing = 2;

// Pocket slack (mm), applied on envelope edges
pocket_clearance = 0.6;

// Pocket must not eat the OD strip where M2 screws pass (see servo_screw_holes).
outer_mount_keep = 3;

// Into central bore: enough so radial case depth (22.8 mm) clears inner wall + clearance
pocket_into_bore = 72;

// Z position of servo spline vs geometric center of the pocket (align with calipers).
servo_output_z_offset_from_body_center = 0;

// ----- M2 mounting through-holes (two per servo, ±spacing/2 along Z from servo output Z)
m2_mount_hole_d = 2; // mm nominal M2; enlarge slightly if screws bind in printed plastic

// ----- Optional wire routing through mid band
wire_hole_enable = true;
wire_hole_d = 8;
wire_hole_azimuth = 45;   // deg, single hole in mid band (avoid servo quadrants)
wire_hole_z = 0;          // 0 = mid of mid_band; else offset along Z from that mid

// ----- Tessellation
$fn = 64;

// Pocket tangential = side-to-side; along Z use max(case, tab spacing) + clearance so ears fit.
sg90_body_w = sg90_case_w + pocket_clearance;
sg90_body_z = max(sg90_case_z, sg90_hole_spacing) + pocket_clearance;

assert(wall_thickness + pocket_into_bore >= sg90_case_radial + pocket_clearance,
       "Increase wall_thickness or pocket_into_bore so SG90 fits radially");
assert(outer_mount_keep > 0 && outer_mount_keep < wall_thickness,
       "outer_mount_keep must leave an OD strip thinner than full wall but non-zero");
assert(mid_band_len >= sg90_body_z, "Increase mid_band_len to clear the servo pocket along Z");

// ----- Derived
shoulder_outer_r = (body_tube_id - clearance) / 2;
middle_outer_r = body_tube_od / 2;
inner_r = middle_outer_r - wall_thickness;
total_h = shoulder_bot_len + mid_band_len + shoulder_top_len;
mid_z0 = shoulder_bot_len;
mid_z1 = shoulder_bot_len + mid_band_len;
servo_z_center = (mid_z0 + mid_z1) / 2;
mount_r_mid = (inner_r + middle_outer_r) / 2;

module coupler_solid() {
  union() {
    cylinder(h = shoulder_bot_len, r = shoulder_outer_r);
    translate([0, 0, shoulder_bot_len])
      cylinder(h = mid_band_len, r = middle_outer_r);
    translate([0, 0, shoulder_bot_len + mid_band_len])
      cylinder(h = shoulder_top_len, r = shoulder_outer_r);
  }
}

module servo_pocket(angle_deg) {
  dz = sg90_body_z;
  dw = sg90_body_w;
  r_in = inner_r - pocket_into_bore;
  r_out = middle_outer_r - outer_mount_keep;
  dr_total = r_out - r_in;
  rotate([0, 0, angle_deg + servo_azimuth_offset])
    translate([(r_in + r_out) / 2, 0, servo_z_center])
      cube([dr_total, dw, dz], center = true);
}

// Two M2 holes through the OD mounting strip: above/below servo spline along Z.
module servo_screw_holes(angle_deg) {
  servo_output_z = servo_z_center + servo_output_z_offset_from_body_center;
  half = (sg90_hole_spacing / 2) + m2_mount_hole_spacing;
  rotate([0, 0, angle_deg + servo_azimuth_offset])
    for (tz = [-half, half])
      translate([mount_r_mid, 0, servo_output_z + tz])
        rotate([0, 90, 0])
          cylinder(h = outer_mount_keep + 6, d = m2_mount_hole_d, center = true);
}

module wire_routing() {
  if (wire_hole_enable) {
    zc = (mid_z0 + mid_z1) / 2 + wire_hole_z;
    rotate([0, 0, wire_hole_azimuth])
      translate([mount_r_mid, 0, zc])
        rotate([0, 90, 0])
          cylinder(h = wall_thickness + 6, d = wire_hole_d, center = true);
  }
}

difference() {
  coupler_solid();

  translate([0, 0, -0.01])
    cylinder(h = total_h + 0.02, r = inner_r);

  for (a = [0 : 90 : 270]) {
    servo_pocket(a);
    servo_screw_holes(a);
  }

  wire_routing();
}
