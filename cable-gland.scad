/*
 * Split Cable Gland
 *
 * A threaded cable gland (hex head, threaded shank, nut) whose body is split
 * so a cable that already has a connector on it can be laid in from the side:
 *
 *   body: hex head with a channel through its -y half, plus a half-ring shank
 *   plug: the other half of the shank plus a tab that slides into the channel
 *         along dovetail guides
 *   nut:  ordinary nut
 *
 * Requires BOSL2: https://github.com/BelfrySCAD/BOSL2
 *
 * Usage:
 *   include <hosl/cable-gland.scad>
 *
 *   cable_gland(od=12, id=6);                  // all parts, laid out
 *   cable_gland(od=12, id=6, part="plug");     // one part
 *   cable_gland(od=12, id=6, layout=false);    // assembled position
 */

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

module __end_customizer_options__() { }

// od:            outer (thread) diameter, the panel hole size
// id:            cable diameter
// bore_slop:     clearance added to the cable diameter at the crests of the grip thread
// nut_height:    nut height; the threaded shank is nut_height + 5 long
// pitch:         main thread pitch
// nut_slop:      nut thread clearance (BOSL2 adds 4x this to the nut diameter)
// guide_slop:    clearance on each side of the plug's dovetail guides
// grip_depth:    how far the grip thread ridges project into the bore; the ridge
//                crests are at id + bore_slop, the grooves are deeper
// grip_pitch:    grip thread pitch
// head_width:    head across flats (default od*1.5)
// head_height:   head height (default nut_height+1)
// channel_width: head channel / plug tab width, must exceed id (default od*0.7)
// guide_depth:   how far the dovetail guides project from the channel wall
// guide_base:    guide thickness at its base
// part:          "all", "body", "plug" or "nut"
// layout:        true: parts side by side for printing;
//                false: assembled position, nut slid onto the shank
module cable_gland(
    od = 12,
    id = 6,
    bore_slop = 0.3,
    nut_height = 5,
    pitch = 2,
    nut_slop = 0.2,
    guide_slop = 0.2,
    grip_depth = 0.3,
    grip_pitch = 2.5,
    head_width,
    head_height,
    channel_width,
    guide_depth = 0.4,
    guide_base = 2,
    fn = 64,
    part = "all",
    layout = true
) {
    hd = is_undef(head_width) ? od*1.5 : head_width;
    eph = is_undef(head_height) ? nut_height+1 : head_height;
    sw = is_undef(channel_width) ? od*0.7 : channel_width;
    iph = nut_height + 5;
    $fn = fn;

    module gland() {
        diff()
        hex_head(hd, eph) {
            attach(TOP, BOTTOM, overlap=0.01)
                threaded_rod(d=od, l=iph, pitch=pitch, bevel2=true);
            tag("remove") position(BOTTOM) down(1)
                trapezoidal_threaded_rod(d=id+bore_slop+2*grip_depth, l=eph+iph+2, pitch=grip_pitch,
                                         thread_depth=grip_depth,
                                         internal=true, anchor=BOTTOM);
        }
    }

    // y<0 side of the gland: head channel with dovetail guides, plus the
    // y<0 half of the shank. Female is the cut for the body; the plug is the
    // gland intersected with the male version.
    module plug_region(female) {
        c = female ? 0 : guide_slop;
        down(1) cuboid([sw-2*c, hd, eph+1], anchor=BOTTOM+BACK);
        up(eph) cuboid([2*hd, hd, iph+2], anchor=BOTTOM+BACK);
        for (m = [0,1]) mirror([m,0,0])
            translate([sw/2-c, 0, eph/2])
                guide(hd, guide_depth, guide_base, female ? guide_slop : 0);
    }

    if (part == "body" || part == "all")
        difference() {
            gland();
            plug_region(true);
        }
    if (part == "plug" || part == "all")
        translate(layout ? [0, -(hd/2+2), 0] : [0, 0, 0])
            intersection() {
                gland();
                plug_region(false);
            }
    if (part == "nut" || part == "all")
        translate(layout ? [-1.7*od, 0, 0] : [0, 0, eph+1])
            threaded_nut(nutwidth=od+5, id=od, h=nut_height, pitch=pitch,
                         bevel=true, ibevel=false, anchor=BOTTOM,
                         $slop=nut_slop);
}

// Hex head with the corners turned down by a 45 degree cone top and bottom.
module hex_head(width, height, anchor=BOTTOM, spin=0, orient=UP) {
    attachable(anchor, spin, orient, d=width/cos(30), h=height) {
        intersection() {
            regular_prism(6, h=height, id=width, center=true);
            cyl(h=height, d=width+height, chamfer=height/2);
        }
        children();
    }
}

// A 45 degree dovetail guide running along -y: `depth` deep, `base` thick at
// its base and 2*depth thicker at the tip. g grows it on all sides.
module guide(length, depth, base, g=0) {
    rotate([90,0,0]) linear_extrude(height=length)
        offset(delta=g)
            polygon([[-0.05,-base/2],[depth,-base/2-depth],
                     [depth,base/2+depth],[-0.05,base/2]]);
}
