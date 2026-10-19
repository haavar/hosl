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
 *   include <hosl/gridfinity-rugged-box.scad>;
 *
 *   // 4x3 cells, 3U bins: lid and base side by side with a label
 *   grugged(4, 3, 3, part="side-by-side", label=true, label_text="Screws");
 *
 *   // Every option, with its default:
 *   grugged(
 *       gx, gy, gz,                      // footprint in 42 mm cells, height in 7 mm units
 *       part="side-by-side",             // "bottom", "top", "latch", "handle", "label",
 *                                        // "side-by-side", "assembled_open", "assembled_closed"
 *       grid=true,                       // foot pockets in the base, blocks in the lid
 *       corner_radius=3.5,               // interior; keep at or below 4 so bins fit
 *       block_clearance=0.3,             // shrink each lid block per side (37.2 mm -> 36.6 mm)
 *       hinge_relief=1,                  // trim hinge-side block faces so the lid can swing in; 0 = off
 *       block_frame=3,                   // hollow lid blocks with a frame this wide; 0 = solid
 *       block_frame_chamfer=1.5,         // inner chamfer on the frame tip, mm
 *       edge_chamfer_proportion=0.4,
 *       lip_seal_type="wedge",           // "none", "wedge", "square", "filament-1.75mm"
 *       reinforced_corners=false,
 *       latch_type="auto",               // "auto", "draw" or "clip"; auto uses clip on short boxes
 *       latch_count=0,                   // 0 = automatic from the width
 *       top_grip=false,
 *       hinge_end_stops=false,
 *       handle=true,                     // needs two latches and a base about 7U or taller
 *       label=false, label_text="", label_text_size=10,
 *       wall_thickness=2.4, lip_thickness=1.86, rib_width=4.0,
 *       latch_width=22, latch_screw_separation=20, size_tolerance=0.05
 *   );
 *
 *   Export one part from the command line, e.g. the base of a 4x3x3 box:
 *   OpenSCAD --backend=manifold -o base.stl file.scad   // file.scad holds the line
 *                                                       // grugged(4, 3, 3, part="bottom");
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

// Rounded rectangle: half width hx, front (-y) half depth hm, hinge-side (+y) half depth hp
module _gf_cell(hx, hm, hp, r) {
    rr = max(0.01, min(r, hx, (hm + hp) / 2));
    translate([0, (hp - hm) / 2])
    offset(r = rr) square([(hx - rr) * 2, hm + hp - rr * 2], center = true);
}

// Measured hinge-side relief of the lid blocks (see hinge_relief in grugged()).
// The reference lid trims the +y face of each block, more the closer the block
// is to the hinge, so the lid can swing in on its arc. Slope of the trim (mm of
// relief per mm of depth below gf_relief_start) by distance u from the hinge-side
// wall to the block centre; the trim stops growing at gf_relief_end.
gf_relief_start = 3.2;
gf_relief_end = 5.0;
gf_relief_slopes = [[0, 1.0], [21, 1.0], [63, 0.64], [105, 0.37], [147, 0.13], [189, 0]];

function _gf_interp(table, u) = (
    u <= table[0][0] ? table[0][1]
    : u >= table[len(table) - 1][0] ? table[len(table) - 1][1]
    : let (i = [for (j = [0 : len(table) - 2]) if (u >= table[j][0] && u < table[j + 1][0]) j][0])
      table[i][1] + (table[i + 1][1] - table[i][1]) * (u - table[i][0]) / (table[i + 1][0] - table[i][0])
);

function _gf_relief(d, slope) = slope * max(0, min(d, gf_relief_end) - gf_relief_start);

// One pocket (base) or block (lid): stack of hulled slabs following the profile.
// slope > 0 trims the hinge-side (+y) face as described above.
module _gf_pocket(profile, inset = 0, slope = 0, rmin = 0.01) {
    // inset shrinks the shape on every side (corner radius shrinks with it)
    r_of = function(hw) max(hw - 17, rmin);
    prof = [for (p = profile) [p[0], p[1] - inset]];
    n = len(prof);
    // continue the opening 0.5 mm past the last point so cuts are clean
    last = prof[n - 1];
    lr = _gf_relief(last[0], slope);
    hull() {
        translate([0, 0, last[0]]) linear_extrude(0.001) _gf_cell(last[1], last[1], last[1] - lr, r_of(last[1]));
        translate([0, 0, last[0] + 0.5]) linear_extrude(0.001) _gf_cell(last[1], last[1], last[1] - lr, r_of(last[1]));
    }
    for (i = [0 : n - 2]) {
        r0 = _gf_relief(prof[i][0], slope);
        r1 = _gf_relief(prof[i + 1][0], slope);
        hull() {
            translate([0, 0, prof[i][0]]) linear_extrude(0.001)
                _gf_cell(prof[i][1], prof[i][1], prof[i][1] - r0, r_of(prof[i][1]));
            translate([0, 0, prof[i + 1][0]]) linear_extrude(0.001)
                _gf_cell(prof[i + 1][1], prof[i + 1][1], prof[i + 1][1] - r1, r_of(prof[i + 1][1]));
        }
    }
}

module _gf_pockets(gx, gy, profile, inset = 0, relief = 0, rmin = 0.01) {
    for (ix = [0 : gx - 1], iy = [0 : gy - 1])
        translate([(ix - (gx - 1) / 2) * gf_pitch, (iy - (gy - 1) / 2) * gf_pitch, 0])
        _gf_pocket(profile, inset,
            relief * _gf_interp(gf_relief_slopes, (gy - 1 - iy) * gf_pitch + gf_pitch / 2), rmin);
}

// Frame blocks (block_frame > 0): the lid block is hollowed from its tip, leaving a
// wall of the given width around the cell. The hollow stops at the lid's top plate,
// its inner tip edge gets a 45 degree chamfer (the outer tip already has one) and
// its inner corners are rounded. The chamfer is limited so at least this much
// flat is left on the tip of the frame wall.
gf_frame_min_flat = 0.8;
gf_frame_inner_radius = 1.5;

function _gf_hw_at(p, d) = (
    d <= p[0][0] ? p[0][1]
    : d >= p[len(p) - 1][0] ? p[len(p) - 1][1]
    : let (i = [for (j = [0 : len(p) - 2]) if (d >= p[j][0] && d < p[j + 1][0]) j][0])
      p[i][1] + (p[i + 1][1] - p[i][1]) * (d - p[i][0]) / (p[i + 1][0] - p[i][0])
);

function _gf_cavity_profile(profile, w, c, d_roof) = (
    let (
        n = len(profile),
        dl = profile[n - 1][0]
    )
    concat(
        [[d_roof, _gf_hw_at(profile, d_roof) - w]],
        [for (p = profile) if (p[0] > d_roof && p[0] < dl - c) [p[0], p[1] - w]],
        [[dl - c, _gf_hw_at(profile, dl - c) - w], [dl, profile[n - 1][1] - w + c]]
    )
);

// Base: ribs plate with foot pockets cut into it and the floor.
// Lid: the reference lid is the inverse -- solid blocks hang from the ceiling
// (they drop into the openings at the top of the bins) with grooves between.
module _gf_body(part, gx, gy, profile, corner_radius, block_clearance = 0, hinge_relief = 0, block_frame = 0, frame_chamfer = 1.5) {
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
            if (block_frame > 0) {
                difference() {
                    _gf_pockets(gx, gy, profile, block_clearance, hinge_relief);
                    _gf_pockets(gx, gy,
                        _gf_cavity_profile(profile, block_frame, min(frame_chamfer, block_frame - gf_frame_min_flat), $b_wall_thickness),
                        block_clearance, hinge_relief, gf_frame_inner_radius);
                }
            } else {
                _gf_pockets(gx, gy, profile, block_clearance, hinge_relief);
            }
        }
    }
}

module _gf_grid_solid(gx, gy, profile, corner_radius) {
    h = profile[len(profile) - 1][0];
    linear_extrude(h)
    offset(r = corner_radius)
    square([gx * gf_pitch - corner_radius * 2, gy * gf_pitch - corner_radius * 2], center = true);
}

// Latch fit. The draw latch lever hangs about 31 mm below its pivot, which on a
// short box ends up below the base. The clip latch is only latch_screw_separation
// + 11.25 mm long, so a shorter separation keeps it inside the box.
gf_draw_lever = 31.31;      // measured: lever length below the draw latch pivot
gf_latch_margin = 0.1;      // keep the latch this far above the base bottom

function _gf_draw_bottom(base_outer, sep, lid_outer) = (
    base_outer - (sep - min(lid_outer / 2, sep - screw_eyelet_radius * 1.25)) - gf_draw_lever
);

function _gf_clip_bottom(base_outer, sep, lid_outer) = (
    base_outer + top_hinge_eyelet_position_tolerance
    + min(lid_outer / 2, screw_eyelet_radius * 2.0, sep / 2)
    - sep - latch_base_size * 2.5
);

// Largest separation (stepping down 0.5 mm from sep) at which the clip latch fits
function _gf_clip_sep(base_outer, sep, lid_outer) = (
    (sep <= 6 || _gf_clip_bottom(base_outer, sep, lid_outer) >= gf_latch_margin)
        ? sep
        : _gf_clip_sep(base_outer, sep - 0.5, lid_outer)
);

/*
 * Gridfinity rugged box
 *
 *  - gx, gy: footprint in Gridfinity cells (interior = gx*42 x gy*42 mm)
 *  - gz: usable bin height in 7 mm units
 *  - part: any rbox_part() value ("bottom", "top", "latch", "handle", "label",
 *    "side-by-side", "assembled_closed", "assembled_open", ...)
 *  - block_clearance: shrink each lid block by this much per side. The measured
 *    block is 37.2 mm wide, which is tight in a 37.3 mm bin opening, especially
 *    when the lid swings in at an angle. 0.3 gives 36.6 mm blocks; 0 restores
 *    the measured size.
 *  - hinge_relief: scale of the measured hinge-side trim on the lid blocks (1 =
 *    as measured, 0 = off). The lid swings in on an arc about the hinge, so the
 *    blocks nearest the hinge have their hinge-side face trimmed, up to 1.8 mm
 *    on the row next to the hinge. Without it the rear bins can bind.
 *  - block_frame: width in mm (default 3) of the frame left around each lid block
 *    after hollowing it from its tip. This saves filament and print time, and the
 *    hollow has a chamfered inner edge and rounded corners. 0 keeps the blocks
 *    solid. Not test-printed.
 *  - block_frame_chamfer: size of the 45 degree chamfer on the inner tip edge of
 *    the frame, in mm (default 1.5). Limited so 0.8 mm of flat stays on the tip.
 *  - latch_type: "auto" (default) uses the draw latch when it fits inside the
 *    box and otherwise the clip latch, with latch_screw_separation reduced just
 *    enough that it stays inside (about 8U or taller for the draw latch). "draw"
 *    and "clip" force a type and use latch_screw_separation as given.
 *  - everything else forwards to rbox() / rbox_size_adjustments()
 */
module grugged(
    gx, gy, gz,
    part = "side-by-side",
    grid = true,
    corner_radius = 3.5,
    block_clearance = 0.3,
    hinge_relief = 1,
    block_frame = 3,
    block_frame_chamfer = 1.5,
    edge_chamfer_proportion = 0.4,
    lip_seal_type = "wedge",
    reinforced_corners = false,
    latch_type = "auto",
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

    // Latch selection
    draw_fits = _gf_draw_bottom(base_outer, latch_screw_separation, gf_lid_outer_height)
        >= gf_latch_margin;
    use_type = latch_type != "auto" ? latch_type : (draw_fits ? "draw" : "clip");
    use_sep = (latch_type == "auto" && !draw_fits)
        ? _gf_clip_sep(base_outer, latch_screw_separation, gf_lid_outer_height)
        : latch_screw_separation;
    if (latch_type == "auto" && !draw_fits && use_sep < screw_eyelet_radius * 2)
        echo(str("WARNING: latch screw separation ", use_sep, " mm is below the screw eyelet diameter (",
            screw_eyelet_radius * 2, " mm); the clip latch eyelets will overlap"));
    if (part == "assembled_closed" || part == "side-by-side")
        echo(str("Latch: ", use_type, ", screw separation ", use_sep, " mm"));

    rbox(
        width = gx * gf_pitch,
        length = gy * gf_pitch,
        bottom_height = base_inner,
        top_height = lid_inner,
        corner_radius = corner_radius,
        edge_chamfer_proportion = edge_chamfer_proportion,
        lip_seal_type = lip_seal_type,
        reinforced_corners = reinforced_corners,
        latch_type = use_type,
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
        latch_screw_separation = use_sep,
        size_tolerance = size_tolerance
    )
    rbox_part(part) {
        if (grid) _gf_body("bottom", gx, gy, gf_base_profile, corner_radius); else rbox_bottom();
        if (grid) _gf_body("top", gx, gy, gf_lid_profile, corner_radius, block_clearance, hinge_relief, block_frame, block_frame_chamfer); else rbox_top();
    }
}
