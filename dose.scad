/*
 * Parametric Round Container with Threaded Cap
 * Dose Library — BOSL2 edition
 *
 * BOSL2-based reimplementation of the original dose library, with the
 * same public API.
 *
 * Requires: BOSL2 (https://github.com/BelfrySCAD/BOSL2)
 *
 * Notes vs the original:
 *  - Threads use BOSL2's thread_helix(), which produces a symmetric
 *    trapezoidal thread. The mapping from cut_thread_percent to BOSL2
 *    parameters preserves the original crest/root proportions
 *    (flank_angle stays at 45°, thread_depth scales).
 *  - Rounded edges use cyl(rounding1=…) instead of a hand-rolled
 *    rotate_extrude profile.
 *
 * Usage:
 *   include <dose.scad>           // must be `include`, not `use` — see below
 *
 *   dose(inner_diameter=30, inner_height=50) {
 *       dose_can();
 *       translate([50, 0, 0])
 *       dose_cap();
 *   }
 *
 *   // Or use dose_part() for layout and section view options:
 *   dose(inner_diameter=30, inner_height=50)
 *       dose_part("all", layout=true, section=false);
 *
 * Why `include` and not `use`?
 *   BOSL2's attachment system relies on globally-set `$` variables that
 *   `use` does not propagate to the caller. `include` re-exposes them
 *   and everything works. If you'd rather `use` this file, first do
 *   `include <BOSL2/std.scad>` in the calling script.
 */

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

module __end_customizer_options__() { }

/*
 * Main setup module — same arguments as the original dose().
 */
module dose(
    inner_diameter    = 13,
    inner_height      = 122,
    wall_thickness    = 2,
    cap_wall_thickness = 2,
    floor_thickness   = 3,
    rim_height        = 3,
    rim_diameter      = 85.4,
    thread_height     = 10,
    thread_turns      = 4,
    cut_thread_percent = 10,
    smooth_sides      = true,
    corner_radius     = 1.5,
    fn                = 128,
    fit_tolerance     = 0.5
) {
    $d_inner_r       = inner_diameter / 2;
    $d_inner_h       = inner_height;
    $d_wall          = wall_thickness;
    $d_cap_wall      = cap_wall_thickness;
    $d_floor         = floor_thickness;
    $d_rim_height    = rim_height;
    $d_rim_r         = rim_diameter / 2;
    $d_thread_h      = thread_height;
    $d_turns         = thread_turns;
    $d_smooth_sides  = smooth_sides;
    $d_corner_r      = corner_radius;
    $d_fn            = fn;
    $d_fit           = fit_tolerance;

    // Thread geometry, matched to the original library:
    //   thread_depth = (pitch/2) * (100 - cut_thread_percent) / 100
    //   flank_angle  = 45°  (invariant when thread_depth scales with cut_pct)
    $d_pitch         = thread_height / thread_turns;
    $d_thread_depth  = ($d_pitch / 2) * (100 - cut_thread_percent) / 100;

    children();
}

module dose_can() { _dose_can(); }
module dose_cap() { _dose_cap(); }

/*
 * Render a part by name with optional layout and section view.
 * Same signature as the original dose_part().
 */
module dose_part(
    part           = "all",
    layout         = true,
    section        = false,
    print_distance = 5
) {
    difference() {
        _dose_layout(part, layout, print_distance);
        if (section) {
            rotate([0, 0, 180])
            translate([-$d_inner_r * 2 - 100, 0, -0.05])
                cube([
                    ($d_inner_r + 100) * 2,
                    $d_inner_r + 100,
                    $d_inner_h + $d_floor * 2 + $d_fit + 0.1
                ]);
        }
    }
}

module _dose_layout(part, layout, print_distance) {
    cap_outer_d = $d_inner_r * 2 + 2 * $d_wall + 2 * ($d_pitch / 2) + 2 * $d_cap_wall;
    if (part == "all" || part == "can") _dose_can();
    if (part == "all" || part == "cap") {
        translate([
            0,
            (layout && part == "all") ? -(cap_outer_d + print_distance) : 0,
            layout ? 0 : $d_inner_h + $d_floor * 2 + $d_fit / 2
        ])
        rotate([0, layout ? 0 : 180, 0])
        _dose_cap();
    }
}

module _dose_can() {
    body_r       = $d_inner_r + $d_wall;
    body_d       = body_r * 2;
    total_h      = $d_inner_h + $d_floor;
    thread_bot_z = total_h - $d_thread_h;
    collar_h     = $d_pitch;
    collar_r     = body_r + $d_pitch / 2 + ($d_smooth_sides ? $d_cap_wall : 0);
    support_h    = $d_wall * 2;

    difference() {
        union() {
            // Main body with fillet on the outer bottom edge
            cyl(
                r = body_r,
                h = total_h,
                rounding1 = $d_corner_r,
                anchor = BOTTOM,
                $fn = $d_fn
            );

            // External thread wrapping the top of the body. thread_helix
            // extends the polygon axially by ±pitch/2 past `h` on each end,
            // so we start the helix pitch/2 below thread_bot_z (that hides
            // the bottom polygon inside the collar) and trim above the top
            // face for the upper overshoot.
            up(thread_bot_z - $d_pitch / 2)
            thread_helix(
                d = body_d,
                pitch = $d_pitch,
                turns = $d_turns,
                thread_depth = $d_thread_depth,
                flank_angle = 45,
                anchor = BOTTOM,
                lead_in_ang2 = -45,   // taper last 45° at the top (matches the original's er=45)
                $fn = $d_fn
            );

            // Collar directly below the threads (also hides the bottom of the sweep)
            up(thread_bot_z - collar_h)
            cyl(
                r = collar_r,
                h = collar_h,
                anchor = BOTTOM,
                $fn = $d_fn
            );

            // Chamfered support ramp below the collar
            up(thread_bot_z - collar_h - support_h)
            cyl(
                r1 = body_r,
                r2 = collar_r,
                h  = support_h,
                anchor = BOTTOM,
                $fn = $d_fn
            );
        }

        // Trim any thread material that spilled above the top face
        up(total_h)
        cyl(
            r = body_r + $d_pitch + 1,
            h = $d_pitch + 1,
            anchor = BOTTOM,
            $fn = $d_fn
        );

        // Interior hollow with a matching inside fillet at the floor
        up($d_floor)
        cyl(
            r = $d_inner_r,
            h = $d_inner_h + 0.05,
            rounding1 = $d_corner_r,
            anchor = BOTTOM,
            $fn = $d_fn
        );

        // Interior rim clearance near the top. Only applied when the rim
        // widens the interior but stays inside the wall — otherwise it
        // would eat the top of the container (including the threads).
        body_r_local = $d_inner_r + $d_wall;
        if ($d_rim_height > 0 && $d_rim_r > $d_inner_r && $d_rim_r < body_r_local) {
            up($d_floor + $d_inner_h - $d_rim_height)
            cyl(
                r = $d_rim_r,
                h = $d_rim_height + 0.05,
                anchor = BOTTOM,
                $fn = $d_fn
            );
        }
    }
}

module _dose_cap() {
    pocket_r = $d_inner_r + $d_wall + $d_pitch / 2 + $d_fit;
    outer_r  = $d_inner_r + $d_wall + $d_pitch / 2 + $d_cap_wall;
    body_h   = $d_thread_h + $d_floor;
    // For an internal thread, `d` is the crest (tip) diameter. We want ridge
    // roots to land on the pocket wall (radius pocket_r), so:
    //   d/2 + thread_depth = pocket_r  →  d = 2*(pocket_r - thread_depth)
    thread_d = 2 * (pocket_r - $d_thread_depth);

    difference() {
        // Body minus pocket; then union internal thread ridges into the pocket.
        // The cap is built with its closed end at z=0, so it gets rounding1 there
        // (the fillet becomes the top when the cap is flipped for assembly).
        union() {
            difference() {
                cyl(
                    r = outer_r,
                    h = body_h,
                    rounding1 = $d_corner_r,
                    anchor = BOTTOM,
                    $fn = $d_fn
                );
                up($d_floor)
                cyl(
                    r = pocket_r,
                    h = $d_thread_h + 0.05,
                    rounding1 = $d_corner_r,
                    anchor = BOTTOM,
                    $fn = $d_fn
                );
            }

            // Internal thread ridges. thread_helix(internal=true) is added
            // (union), not subtracted — see BOSL2 threading.scad docs.
            // Shift up by pitch/2 so the bottom polygon overshoot lands in
            // the floor material rather than sticking up into the pocket.
            up($d_floor + $d_pitch / 2)
            thread_helix(
                d = thread_d,
                pitch = $d_pitch,
                turns = $d_turns,
                thread_depth = $d_thread_depth,
                flank_angle = 45,
                internal = true,
                anchor = BOTTOM,
                lead_in_ang2 = -45,   // taper the ridges at the cap's open end
                $fn = $d_fn
            );
        }

        // Trim any thread material that spilled outside the pocket ends
        up(body_h)
        cyl(r = outer_r + 1, h = $d_pitch + 1, anchor = BOTTOM, $fn = $d_fn);
        down($d_pitch + 1)
        cyl(r = outer_r + 1, h = $d_pitch + 1, anchor = BOTTOM, $fn = $d_fn);
    }
}
