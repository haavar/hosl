/*
 * Gridfinity Rugged Case Generator (WORK IN PROGRESS)
 *
 * STATUS: work in progress. Not test-printed. Known gaps: corner details of
 * the reference case are not reproduced, pocket/block corner radii are
 * estimated, labels are untested, seal/latch fit is unverified, and handles
 * only appear on boxes about 7U and taller (library rule).
 *
 * Specify a rugged case in Gridfinity units (gx x gy footprint, gz bin
 * heights). The base gets a Gridfinity foot-pocket grid and the lid a grid of
 * blocks that drop into the bin tops.
 *
 * Built on:
 *   rugged-box-library.scad -- "Customizable and Parametric Rugged Storage Box"
 *   by smkent (GitHub) / bulbasaur0 (Printables), CC BY-SA 4.0. The box body,
 *   hinges, latches, handle and label all come from that library.
 *   (original URL not recorded; check before redistributing)
 *
 * Grid dimensions (42 mm pitch, foot/block profiles, vertical stack-up) were
 * measured from existing Gridfinity rugged case lid and base STLs.
 * Interior = n * 42 mm exactly, bin foot bottom 1.2 mm above the outside
 * floor, lid blocks 0.6 mm above the top of an n*7 mm bin.
 *
 * Example:
 *   include <gridfinity-rugged-box.scad>;
 *   grugged(4, 3, 3, part="side-by-side", handle=true, label=true, label_text="Screws");
 *
 * Requires: rugged-box-library.scad in the same folder
 * License: Creative Commons - Attribution-ShareAlike (CC BY-SA 4.0), inherited from the library
 */

include <rugged-box-library.scad>;

// Gridfinity constants
gf_pitch = 42;
gf_unit_height = 7;

// Measured profiles: [distance from the outside face, half width of one cell].
// Base: pockets cut into the floor, opening toward the interior at the last point.
// Lid: the same shape is a solid block hanging from the ceiling; its last point
// is the narrow end that enters the bin.
gf_base_profile = [[1.2, 18.15], [1.9, 18.85], [3.7, 18.85], [5.35, 20.5]];
// Lid blocks: widest at the ceiling, narrowest at the free end.
gf_lid_profile = [[2.0, 19.75], [3.2, 18.6], [5.0, 18.6], [5.8, 17.85]];

// Measured vertical stack-up (mm)
gf_lid_outer_height = 12.9;     // lid outside face to rim
gf_stack_extra = 7.5;           // closed outer height = gz * 7 + this

module _gf_cell(hw, r) {
    rr = max(0.01, min(r, hw));
    offset(r = rr) square((hw - rr) * 2, center = true);
}

// One pocket: stack of hulled slabs following the profile
module _gf_pocket(profile) {
    r_of = function(hw) hw - 17;
    n = len(profile);
    // continue the opening 0.5 mm past the last point so cuts are clean
    last = profile[n - 1];
    hull() {
        translate([0, 0, last[0]]) linear_extrude(0.001) _gf_cell(last[1], r_of(last[1]));
        translate([0, 0, last[0] + 0.5]) linear_extrude(0.001) _gf_cell(last[1], r_of(last[1]));
    }
    for (i = [0 : n - 2]) {
        z0 = profile[i][0];
        z1 = profile[i + 1][0];
        hull() {
            translate([0, 0, z0]) linear_extrude(0.001) _gf_cell(profile[i][1], r_of(profile[i][1]));
            translate([0, 0, z1]) linear_extrude(0.001) _gf_cell(profile[i + 1][1], r_of(profile[i + 1][1]));
        }
    }
}

module _gf_pockets(gx, gy, profile) {
    for (ix = [0 : gx - 1], iy = [0 : gy - 1])
        translate([(ix - (gx - 1) / 2) * gf_pitch, (iy - (gy - 1) / 2) * gf_pitch, 0])
        _gf_pocket(profile);
}

// Base: ribs plate with foot pockets cut into it and the floor.
// Lid: the reference lid is the inverse -- solid blocks hang from the ceiling
// (they drop into the openings at the top of the bins) with grooves between.
module _gf_body(part, gx, gy, profile, corner_radius) {
    if (part == "bottom") {
        difference() {
            union() {
                rbox_bottom();
                _gf_grid_solid(gx, gy, profile, corner_radius);
            }
            _gf_pockets(gx, gy, profile);
        }
    } else {
        union() {
            rbox_top();
            _gf_pockets(gx, gy, profile);
        }
    }
}

module _gf_grid_solid(gx, gy, profile, corner_radius) {
    h = profile[len(profile) - 1][0];
    linear_extrude(h)
    offset(r = corner_radius)
    square([gx * gf_pitch - corner_radius * 2, gy * gf_pitch - corner_radius * 2], center = true);
}

/*
 * Gridfinity rugged box
 *
 *  - gx, gy: footprint in Gridfinity cells (interior = gx*42 x gy*42 mm)
 *  - gz: usable bin height in 7 mm units
 *  - part: any rbox_part() value ("bottom", "top", "latch", "handle", "label",
 *    "side-by-side", "assembled_closed", "assembled_open", ...)
 *  - everything else forwards to rbox() / rbox_size_adjustments()
 */
module grugged(
    gx, gy, gz,
    part = "side-by-side",
    grid = true,
    corner_radius = 3.5,
    edge_chamfer_proportion = 0.4,
    lip_seal_type = "wedge",
    reinforced_corners = false,
    latch_type = "draw",
    latch_count = 0,
    top_grip = false,
    hinge_end_stops = false,
    handle = true,
    label = false,
    label_text = "",
    label_text_size = 10,
    wall_thickness = 2.4,
    lip_thickness = 1.86,
    rib_width = 4.0,
    latch_width = 22,
    latch_screw_separation = 20,
    size_tolerance = 0.05
) {
    lid_inner = gf_lid_outer_height - wall_thickness;
    // closed outer height = bottom_outer + lid_outer
    base_outer = gz * gf_unit_height + gf_stack_extra - gf_lid_outer_height;
    base_inner = base_outer - wall_thickness;

    rbox(
        width = gx * gf_pitch,
        length = gy * gf_pitch,
        bottom_height = base_inner,
        top_height = lid_inner,
        corner_radius = corner_radius,
        edge_chamfer_proportion = edge_chamfer_proportion,
        lip_seal_type = lip_seal_type,
        reinforced_corners = reinforced_corners,
        latch_type = latch_type,
        latch_count = latch_count,
        top_grip = top_grip,
        hinge_end_stops = hinge_end_stops,
        handle = handle,
        label = label,
        label_text = label_text,
        label_text_size = label_text_size
    )
    rbox_size_adjustments(
        wall_thickness = wall_thickness,
        lip_thickness = lip_thickness,
        rib_width = rib_width,
        latch_width = latch_width,
        latch_screw_separation = latch_screw_separation,
        size_tolerance = size_tolerance
    )
    rbox_part(part) {
        if (grid) _gf_body("bottom", gx, gy, gf_base_profile, corner_radius); else rbox_bottom();
        if (grid) _gf_body("top", gx, gy, gf_lid_profile, corner_radius); else rbox_top();
    }
}
