    projectBox(50, 100, 30) {
        projectBoxTop();
        translate([100, 0, 0])
        projectBoxBottom();
        pegs(10, 20, board=[12, 22, 5]);
   }
   
/*
 * Parametric Project Box Library
 * hosl
 *
 * A two-part project enclosure with a friction-fit lid, corner screw posts,
 * and heat-insert mounting.
 *
 * Requires BOSL2: https://github.com/BelfrySCAD/BOSL2 (bundled via include
 * below, so the consumer doesn't need to include it separately).
 *
 * Usage:
 *   include <hosl/project-box.scad>
 *
 *   projectBox(85, 125, 30) {
 *       projectBoxTop();
 *       translate([100, 0, 0])
 *       projectBoxBottom();
 *   }
 *
 * Main setup module
 *
 * Arguments:
 *  - x, y:            Inner footprint dimensions in mm
 *  - z:               Total inner height (body + lid combined)
 *  - lid_z:           Height of the lid
 *  - side_thickness:  Wall thickness on all four sides
 *  - floor_thickness: Thickness of the top and bottom faces
 *  - lip_w:           Width of the friction-fit lip
 *  - lip_h:           Height of the friction-fit lip
 *  - lip_play:        Clearance between the lid lip and the body groove
 *  - heat_insert_d:   Diameter of the corner heat insert holes
 *  - heat_insert_l:   Depth of the corner heat insert holes
 *  - fn:              Circle resolution
 *
 */

include <BOSL2/std.scad>


module projectBox(
    x,
    y,
    z,
    lid_z          = 10,
    side_thickness = 2.8,
    floor_thickness = 3,
    lip_w          = 1.2,
    lip_h          = 2,
    lip_play       = 0.3,
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
    $pb_inner_rounding  = 1;
    $pb_lip_w     = lip_w;
    $pb_lip_h     = lip_h;
    $pb_lip_play  = lip_play;
    $pb_insert_d  = heat_insert_d;
    $pb_insert_l  = heat_insert_l;
    $fn           = fn;
    children();
}


module projectBoxTop() {
    color("DarkCyan") 
        difference() {
            _box(x=$pb_x, y=$pb_y, z=$pb_lid_z, wallThickness=$pb_side_t , pegD=$pb_insert_d);
            
            translate([0, 0, $pb_lid_z-($pb_lip_h+$pb_lip_play)/2]) _lip(rect([$pb_lip_w+$pb_lip_play, $pb_lip_h+$pb_lip_play]));   
            
            // screw holes
            xcopies(n=2, spacing=$pb_x-$pb_insert_d) ycopies(n=2, spacing=$pb_y-$pb_insert_d) 
                    translate([0, 0, -$pb_floor_t])
                        cyl(d=6, h=3, anchor=BOTTOM) // todo: hardcoded screw size
                            position(TOP) 
                                cyl(d=3.5, h=$pb_lid_z + $pb_floor_t, anchor=BOTTOM);
        }
    children();
}

module projectBoxBottom() {
    color("steelblue") 
        difference() {
            _box(x=$pb_x, y=$pb_y, z=$pb_z-$pb_lid_z, pegD=$pb_insert_d);
                // holes
            xcopies(n=2, spacing=$pb_x-$pb_insert_d) ycopies(n=2, spacing=$pb_y-$pb_insert_d) translate([0,0,$pb_z-$pb_lid_z]) cylinder(d=$pb_insert_d, h=$pb_insert_l, anchor=TOP);  
        }
    color("orange") translate([0, 0, $pb_z-$pb_lid_z + $pb_lip_h/2]) _lip(rect([$pb_lip_w, $pb_lip_h]));
    children();
}

module _lip(profile) {


    path = turtle([
       
        "move", $pb_x/2 - $pb_inner_rounding - $pb_side_t/2 - $pb_insert_d, 
        "arcleft", $pb_inner_rounding, 90,
        "move", $pb_side_t/2 -$pb_inner_rounding + $pb_insert_d/2,
        "arcright", $pb_insert_d/2+$pb_side_t/2, 90,
        "move", $pb_side_t/2 -$pb_inner_rounding + $pb_insert_d/2,
        "arcleft", $pb_inner_rounding, 90,
        "move", $pb_y/2 -$pb_inner_rounding - $pb_side_t/2 - $pb_insert_d
    ]);
    
    // the 0.001 is to close a gap that I think comes from a rounding error
    xflip_copy() yflip_copy() 
            translate([-0.001, -($pb_y+$pb_side_t)/2+0.001, 0]) 
               path_sweep(profile, path);

}


module _box(x, y, z, wallThickness=$pb_side_t, floorThickness=$pb_floor_t, pegD, innerRounding=$pb_inner_rounding) {
        outerR=pegD/2+wallThickness;
        
        union() {
            // main box
            difference() {
                translate([0,0,-floorThickness]) cuboid([x+wallThickness*2, y+wallThickness*2, z+floorThickness], rounding=outerR, edges="Z", anchor=BOTTOM);
                cuboid([x, y, z], rounding=outerR, edges="Z", anchor=BOTTOM);

            }          
            // corner bracket
            // mirror copy creates the rounded corner on the other side, the flip_copy creates the 4 corners
            bracketDimmenstion=pegD+wallThickness;
           linear_extrude(z)
                xflip_copy() yflip_copy() translate([-x/2+bracketDimmenstion/2,y/2-bracketDimmenstion/2,0]) 
                    mirror_copy([1,1,0]) rect([bracketDimmenstion, bracketDimmenstion], rounding=[-innerRounding, outerR, 0, outerR]);

        }
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
