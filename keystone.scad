/*
 * Keystone Jack Receiver
 *
 * A snap-in receiver for a standard keystone jack, built into the wall of a box:
 *
 *   keystone_cut():   negative, clears the receiver's footprint through the wall
 *   keystone_mount(): positive, the receiver itself, flush with the outside face
 *
 * The jack goes in from inside the box, nose first. Hook the -Y side behind the
 * lip, then swing the tail towards the clip until the clip snaps over the lip.
 * The port faces out through the wall.
 *
 * Fit is tested with a printed receiver and a real jack, with the clip on top.
 * The receiver is 10.15 mm deep, so it works in any wall up to that thickness
 * and sticks out into the box by the difference. Leave room behind it for the
 * jack, which is typically 30-35 mm long and needs to tilt to go in.
 *
 * Requires BOSL2: https://github.com/BelfrySCAD/BOSL2
 *
 * Usage:
 *   include <hosl/keystone.scad>
 *
 *   pos = [0, 65/2 + 2.8, 12.7];   // receiver centre, on the OUTSIDE wall face
 *
 *   difference() {
 *       wall_or_box();
 *       keystone_cut(pos, out=BACK, latch=UP);
 *   }
 *   keystone_mount(pos, out=BACK, latch=UP);
 */

include <BOSL2/std.scad>

module __end_customizer_options__() { }

// pos:   receiver centre, on the outside face
// out:   direction the RJ45 port faces, out of the box
// latch: direction of the jack's spring clip; must be perpendicular to out
module keystone_cut(pos=[0,0,0], out=UP, latch=BACK) {
    size = _keystone_size();

    _keystone_place(pos, out, latch)
        translate([0, 0, 0.01])
            cuboid([size.x, size.y, size.z + 0.01], anchor=TOP);
}

// Union this with the part keystone_cut() was subtracted from. Takes the same
// arguments as keystone_cut(). It is 0.02 mm oversize on the sides to fuse
// with the wall.
module keystone_mount(pos=[0,0,0], out=UP, latch=BACK) {
    size = _keystone_size();

    _keystone_place(pos, out, latch)
        difference() {
            cuboid([size.x + 0.02, size.y + 0.02, size.z], anchor=TOP);
            _keystone_cavity();
        }
}

// Outside of the receiver: [jack width, height along the latch axis, depth].
function _keystone_size() = [18, 26, 10.15];

// Local axes: origin on the outside face at the centre of the receiver, +Z out
// of the box, +Y towards the spring clip, X across the jack.
module _keystone_place(pos, out, latch) {
    move(pos) multmatrix(frame_map(z=out, y=latch)) children();
}

// The jack-shaped void inside the receiver. From the outside face inwards it is
// a narrow front window, a pocket for the hook and clip tips, then a 1.6 mm lip
// around the wider entry opening. Keystone has no public mechanical standard,
// so these numbers are tuned against a real jack.
module _keystone_cavity() {
    e = 0.1;
    width = 14.9;
    depth = _keystone_size().z;

    // A tighter entry opening holds the spring clip down when the jack is seated.
    entry = 20.44 / 2;

    front = 1.75;                // front wall thickness
    pocket_end = front + 6.8;
    pocket_latch = 11.72;        // leaves the clip tip clear of the pocket ceiling
    pocket_hook = 11.39;

    window_latch = -entry + 16.25;   // the window starts at the hook edge of the entry
    land = 0.6;                      // keeps the window's latch edge from being a knife edge
    ramp_end = 9.4;                  // where the slope behind that edge meets the pocket

    // Profile as [Y, Z], extruded along X.
    profile = [
        [ window_latch,  e],
        [ window_latch,  -land],
        [ ramp_end,      -front],
        [ pocket_latch,  -front],
        [ pocket_latch,  -pocket_end],
        [ entry,         -pocket_end],
        [ entry,         -depth - e],
        [-entry,         -depth - e],
        [-entry,         -pocket_end],
        [-pocket_hook,   -pocket_end],
        [-pocket_hook,   -front],
        [-entry,         -front],
        [-entry,         e]
    ];

    rotate([90, 0, 90])
        linear_extrude(height=width, center=true)
            polygon(profile);
}
