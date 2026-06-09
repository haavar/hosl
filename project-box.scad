/*
 * Parametric Project Box Library
 * hosl
 *
 * A two-part project enclosure with a friction-fit lid, corner screw posts,
 * and heat-insert mounting.
 *
 * Requires BOSL2: https://github.com/BelfrySCAD/BOSL2
 * Use `include <BOSL2/std.scad>` before importing this library.
 *
 * Usage:
 *   include <BOSL2/std.scad>
 *   use <project-box.scad>
 *
 *   projectBox(85, 125, 30) {
 *       projectBoxTop();
 *       translate([100, 0, 0])
 *       projectBoxBottom();
 *   }
 */

module __end_customizer_options__() { }

/*
 * Main setup module
 *
 * Arguments:
 *  - x, y:            Inner footprint dimensions in mm
 *  - z:               Total inner height (body + lid combined)
 *  - lid_z:           Height of the lid
 *  - side_thickness:  Wall thickness on all four sides
 *  - floor_thickness: Thickness of the top and bottom faces
 *  - peg_d:           Diameter of the corner screw posts
 *  - rounding:        Corner rounding radius
 *  - lip_w:           Width of the friction-fit lip
 *  - lip_h:           Height of the friction-fit lip
 *  - lip_play:        Clearance between the lid lip and the body groove
 *  - groove_depth:    Extra groove depth in the lid for easier fit
 *  - heat_insert_d:   Diameter of the corner heat insert holes
 *  - heat_insert_l:   Depth of the corner heat insert holes
 *  - fn:              Circle resolution
 *
 * Example:
 *
 *      projectBox(85, 125, 30) {
 *          projectBoxTop();
 *
 *          translate([100, 0, 0])
 *          projectBoxBottom() {
 *              // Mount a PCB on pegs
 *              translate([0, -10, 0])
 *              pegs(31.8, 44.5);
 *          }
 *      }
 */
module projectBox(
    x,
    y,
    z,
    lid_z          = 10,
    side_thickness = 2.8,
    floor_thickness = 3,
    peg_d          = 6,
    rounding       = 3,
    lip_w          = 1.2,
    lip_h          = 2,
    lip_play       = 0.3,
    groove_depth   = 0.8,
    heat_insert_d  = 4.2,
    heat_insert_l  = 7,
    fn             = 100
) {
    $pb_x         = x;
    $pb_y         = y;
    $pb_z         = z;
    $pb_lid_z     = lid_z;
    $pb_side_t    = side_thickness;
    $pb_floor_t   = floor_thickness;
    $pb_peg_d     = peg_d;
    $pb_rounding  = rounding;
    $pb_lip_w     = lip_w;
    $pb_lip_h     = lip_h;
    $pb_lip_play  = lip_play;
    $pb_groove_d  = groove_depth;
    $pb_insert_d  = heat_insert_d;
    $pb_insert_l  = heat_insert_l;
    $fn           = fn;
    children();
}

/*
 * Four mounting pegs for a PCB or circuit board.
 *
 * Places pegs at the four corners of a rectangle matching the board's
 * hole spacing. Each peg has a blind hole for a self-tapping screw or
 * press-fit pin. Works independently of projectBox.
 *
 * Arguments:
 *  - x, y:     Center-to-center spacing of the mounting holes in mm
 *  - d:        Outer diameter of each peg
 *  - h:        Height of each peg
 *  - hole_d:   Diameter of the screw hole
 *  - hole_len: Depth of the screw hole
 *  - board:    Optional [x, y, z] dimensions of the board. When provided,
 *              a transparent preview of the board is shown above the pegs
 *              in preview renders (not included in final output).
 *
 * Example:
 *
 *      // 38x51mm board (e.g. Arduino Nano), with board preview
 *      pegs(31.8, 44.5, board=[38.1, 50.8, 10]);
 */
module pegs(x, y, d=5, h=6, hole_d=2.9, hole_len=5, board=[]) {
    if (len(board) == 3)
        translate([0, 0, h])
            %cuboid(board, anchor=BOTTOM);
    grid_copies(spacing=[x, y])
        difference() {
            cylinder(d=d, h=h);
            translate([0, 0, h - hole_len])
                cylinder(d=hole_d, h=hole_len);
        }
}

// Project box modules

module projectBoxTop() {
    _pbox_top();
}

/*
 * Renders the box body and passes children into its interior coordinate space.
 * Use children to add interior features such as mounting pegs or brackets.
 * Wrap in difference() to subtract cutouts such as cable glands.
 *
 * Example:
 *
 *      difference() {
 *          projectBoxBottom() {
 *              translate([0, -10, 0])
 *              pegs(31.8, 44.5);
 *          }
 *          // Cable gland cutout
 *          translate([0, 60, 4])
 *          ycyl(d=12, h=10, anchor=BOTTOM);
 *      }
 */
module projectBoxBottom() {
    _pbox_bottom();
    children();
}

// Internal modules

module _pbox_top() {
    // Screw center sits at the midpoint of the wall thickness
    screw_offset = $pb_side_t / 2;

    color("DarkCyan")
    difference() {
        _pbox_part($pb_x, $pb_y, $pb_lid_z);
        // Corner screw clearance holes
        xflip_copy() yflip_copy()
            translate([$pb_x/2 - screw_offset, $pb_y/2 - screw_offset, -$pb_floor_t])
                cyl(d=6, h=3, anchor=BOTTOM)
                    position(TOP) cyl(d=3.5, h=$pb_lid_z + $pb_floor_t, anchor=BOTTOM);
        // Lid groove
        translate([0, 0, $pb_lid_z - $pb_lip_h - $pb_groove_d])
            _pbox_lip(
                $pb_x + $pb_side_t,
                $pb_y + $pb_side_t,
                $pb_lip_h + $pb_groove_d,
                $pb_lip_w
            );
    }
}

module _pbox_bottom() {
    screw_offset = $pb_side_t / 2;
    body_z = $pb_z - $pb_lid_z;

    color("steelblue")
    difference() {
        _pbox_part($pb_x, $pb_y, body_z);
        // Corner heat insert holes
        xflip_copy() yflip_copy()
            translate([$pb_x/2 - screw_offset, $pb_y/2 - screw_offset, body_z - $pb_insert_l])
                cylinder(d=$pb_insert_d, h=$pb_insert_l);
    }

    // Friction lip
    color("orange")
    translate([0, 0, body_z])
        _pbox_lip(
            $pb_x + $pb_side_t,
            $pb_y + $pb_side_t,
            $pb_lip_h - $pb_lip_play,
            $pb_lip_w - $pb_lip_play * 2
        );
}

module _pbox_part(x, y, z) {
    difference() {
        translate([0, 0, -$pb_floor_t])
            cuboid(
                [x + $pb_side_t*2, y + $pb_side_t*2, z + $pb_floor_t],
                anchor=BOTTOM, rounding=6, edges="Z"
            );
        linear_extrude(z + 0.01)
            _pbox_profile(x, y);
    }
}

module _pbox_lip(x, y, z, w) {
    linear_extrude(z)
        difference() {
            _pbox_profile(x + w, y + w);
            _pbox_profile(x - w, y - w);
        }
}

module _pbox_profile(x, y) {
    xflip_copy() yflip_copy()
        offset(r=$pb_rounding)
            difference() {
                square([x/2 - $pb_rounding, y/2 - $pb_rounding], anchor=LEFT+FRONT);
                translate([x/2 - $pb_rounding - $pb_peg_d/2, y/2 - $pb_rounding - $pb_peg_d/2, 0])
                    rect(
                        [$pb_peg_d + $pb_rounding, $pb_peg_d + $pb_rounding],
                        rounding=[0, 0, $pb_peg_d/2 + $pb_rounding, 0]
                    );
            }
}
