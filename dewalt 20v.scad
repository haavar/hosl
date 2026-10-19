// =============================================================================
//  dewalt_20v_negative.scad
//
//  Solid NEGATIVE of the DeWalt 20V MAX pack's tool-side interface.
//  difference() this out of your adapter body to get the female pocket.
//
//  Reverse-engineered from  dewalt_battery_dock_r0.step  (tool-side receptacle,
//  "battery dock v7", Autodesk / ST-Developer, 2022-06-15). Feature planes were
//  recovered by ray-casting the tessellated solid and bisecting each face to
//  ~1e-4 mm, so the constants below are the dock's real planes, not estimates.
//
//  ---------------------------------------------------------------------------
//  COORDINATE FRAME  -- identical to the STEP frame, so every constant here is
//  traceable 1:1 to a measured plane and there is no transform to get wrong.
//
//     +X  = width. The pack is symmetric about X = 0.
//     +Y  = height. The pack's top deck sits at Y = +0.500; features rise into
//           +Y and the pack body hangs below into -Y.
//     +Z  = slide axis. The pack is WITHDRAWN toward +Z and SEATS toward -Z.
//           Terminals land at Z ~ -51.8; the pack bottoms out at Z = -58.010.
//
//  ...but that is the MEASUREMENT frame only. It is Y-up, and every BOSL2 body
//  is Z-up, so emitting it raw left the part permanently 90 deg out and you had
//  to hand-rotate it -- which defeats the point of an anchor. The module now
//  applies rot([90,0,0]) internally, at the very end, so what comes OUT is:
//
//     +X  = width          (unchanged)
//     +Z  = UP             pack's height. Deck at Z = +0.500.
//     -Y  = FRONT          the mouth. The pack is withdrawn toward FRONT and
//                          seats toward BACK.
//
//  So UP/DOWN/FRONT/BACK/LEFT/RIGHT all now mean what they say, and
//      difference() { body(); dewalt_20v_negative(anchor="mouth"); }
//  needs no rotate() of its own.
//
//  The constants below stay in the measurement frame so each one remains
//  traceable to a measured plane; the single rotation lives in one place.
//  ---------------------------------------------------------------------------
//
//  WHAT THIS SOLID IS
//  It is the pack's SWEPT volume -- the space the pack occupies plus the space
//  it sweeps through on the way in. That is exactly the void inside the dock,
//  so differencing it reproduces the dock's pocket. Single closed manifold
//  solid (verified: genus 0), one union, no separate bodies.
//
//  NOT included, deliberately: the large cavity above Y = 1.5 in the terminal
//  zone. That volume belongs to the TOOL's contact block, not to the pack;
//  modelling it would gouge a hole through your adapter for no reason.
// =============================================================================

include <BOSL2/std.scad>

// =============================================================================
//  TUNE
// =============================================================================

// --- global fit -------------------------------------------------------------
// The source geometry is a DOCK, so it ALREADY contains DeWalt's own running
// clearance around the pack. clearance = 0 therefore gives a correct sliding
// fit and reproduces the dock exactly. Raise it only to buy back printer
// tolerance (0.10-0.20 is usually plenty on FDM). It is applied outward on
// every face, so the pocket only ever gets roomier -- never tighter.
clearance = 0.0;

// --- open ends --------------------------------------------------------------
// The pocket is open at the front and at the bottom; the pack continues past
// both. These push the negative beyond your adapter's faces so the boolean
// cuts clean. Set them to the dock's own faces (12.170 / -9.922) to reproduce
// the dock exactly instead.
front_extend_z       =  14.000; // dock's front face is at Z = +12.170
bottom_extend_y      = -14.000; // dock's bottom face is at Y =  -9.922

// --- overall ----------------------------------------------------------------
interface_width      =  51.038; // EXACT  full width across the rail band
back_stop_z          = -58.010; // EXACT  pocket back wall; the pack seats here

// --- lower slot (the pack's neck, below the rails) ---------------------------
slot_half_x          =  18.069; // EXACT  X plane
slot_floor_y         =  -9.922; // EXACT  Y plane -- dock's bottom face

// --- rail band (the pack's T-flange / undercut) ------------------------------
// Cross-section is a T: a 36.14-wide neck below, a 51.04-wide flange above.
// NOTE: +/-22.331 and +/-25.519 are NOT the two walls of a narrow channel --
// they are the same flange at two different Z stations. The flange is full
// width in front of rail_step_z and steps in behind it.
rail_floor_y         =  -5.072; // EXACT  Y plane -- underside of the flange
rail_top_y           =   0.500; // EXACT  Y plane -- pack's top deck
rail_half_x          =  25.519; // EXACT  X plane -- full flange half-width
rail_step_z          = -36.028; // EXACT  Z plane -- flange narrows behind this
rail_mid_half_x      =  22.331; // EXACT  X plane -- narrowed flange
rail_nose_front_z    = -47.045; // EXACT  Z plane -- foot of the 45 deg nose
rail_nose_back_z     = -51.307; // EXACT  Z plane -- tip of the flange nose

// --- lower-slot mouth relief (lead-in) ---------------------------------------
// Two independent reliefs open the mouth of the neck out to full flange width:
//   * a 45 deg chamfer along the bottom corners, over flare_back_z..flare_front_z
//   * a steep ramp just under the flange, easing the neck out to rail_half_x
// Neither is fit-critical (both sit outside the seated pack), but both are in
// the dock, so they are reproduced here.
lead_in              = true;    // false gives a plain prismatic lower slot
flare_back_z         = -26.063; // EXACT  Z plane
flare_front_z        = -15.313; // EXACT  Z plane
chamfer_start_y      =  -7.215; // EXACT  Y where the 45 deg chamfer begins
mouth_ramp_top_z     = -18.752; // EXACT  ramp Z at y = rail_floor_y
mouth_ramp_end_y     =  -6.418; // EXACT  Y where the ramp meets flare_front_z
mouth_ramp_slope     =   1.8868;// EXACT  dZ per unit drop in Y

// --- terminals --------------------------------------------------------------
// MEASURED REALITY: this dock has exactly TWO openings through the Y = 0.500
// deck, at X = +/-11.498 -- B+ and B-. The middle pins (TH / ID / cell-balance)
// are NOT broken out by this dock. If your adapter needs them, add their centres
// to terminal_slot_x; they are evenly spaced across the same terminal_zone_z.
terminal_slot_x      = [-11.498, 11.498]; // EXACT  slot centres
terminal_slot_w      =   0.950;           // EXACT  blade thickness
terminal_zone_z      = [-55.010, -48.510];// EXACT  Z extent of the slots
terminal_slot_top_y  =   1.500;           // EXACT  top of the thin slot, i.e.
                                          // the deck thickness. This is the
                                          // SLAT that retains the spade
                                          // terminal: it spans rail_top_y..here
                                          // (1.0 mm as measured). Raise it to
                                          // print a beefier slat; the wire bore
                                          // above starts wherever this ends.

// =============================================================================
//  ADDED FEATURES -- deliberately NOT present in the source dock.
//  Set entry_chamfer = 0 and terminal_bore = false to get back the exact
//  dock-derived negative.
// =============================================================================

// --- insertion lead-in ------------------------------------------------------
// The dock has NO chamfer at its mouth: the pocket walls run dead straight to
// the front face at +/-25.519. That is fine in injection-moulded nylon and
// unpleasant in printed plastic, so this flares the mouth at 45 deg.
// Put entry_face_z at YOUR adapter's front face -- the flare is cut back from
// it, and everything in front of it is oversized (harmlessly, it is outside
// your body anyway).
entry_chamfer        =   1.200; // ADDED  45 deg lead-in depth. 0 disables.
entry_face_z         =  12.170; // dock's own front face

// --- terminal bores ---------------------------------------------------------
// Clearance above each blade for a female spade terminal and its wire.
// IMPORTANT: the bore starts at terminal_slot_top_y, i.e. it sits ON TOP of the
// retaining slat -- it must not eat into it, or the deck loses the thin slot
// that locates and holds the spade. Slat below, round bore above.
terminal_bore        = true;    // ADDED
terminal_bore_d      =   7.000; // ADDED  spade body + wire
terminal_bore_top_y  =  20.000; // ADDED  run it past your adapter's top face

// --- latch catch ------------------------------------------------------------
// A wedge pocket in the deck: 45 deg cam ramp at the back so the latch rides
// down on insertion, near-vertical retention face at the front.
latch_half_x         =  11.845; // EXACT  X plane
latch_top_y          =   5.330; // EXACT  Y plane -- flat roof of the pocket
latch_back_z         =  -6.473; // EXACT  Z plane -- foot of the cam ramp
latch_face_z         =   0.250; // EXACT  Z plane -- THE RETENTION FACE. This is
                                // what stops the pack pulling back out.
latch_ramp_start_y   =   1.377; // EXACT  Y where the cam ramp leaves the wall
latch_ramp_slope     =   1.050; // EXACT  dZ/dY of the cam ramp
latch_face_top_y     =   4.549; // EXACT  Y where the retention face chamfers
latch_face_slope     =   1.000; // EXACT  dZ/dY of that chamfer

// =============================================================================
//  MODULE
// =============================================================================

// -----------------------------------------------------------------------------
//  ANCHORS
//
//  Anchor points are named in the MEASUREMENT frame below but are emitted in
//  the Z-up frame (see COORDINATE FRAME) -- no rotate() needed at the call site.
//
//  THE ONE YOU PROBABLY WANT IS "mouth".
//  It is the centreline point where the MATING FACE meets the ENTRY FACE:
//      X = 0            pack's symmetry plane
//      mating face      slot_floor_y (-9.922): the face your adapter's underside
//                       sits on, pack's 10.42 mm tongue coming up through it.
//                       Emitted as the part's DOWN face.
//      entry face       entry_face_z: the face the pack slides in through.
//                       Emitted as the part's FRONT face.
//  Snap that to the front-bottom edge of your body and the pocket is placed.
//
//  NOTE the mating face is NOT the bottom of this solid. bottom_extend_y
//  (-14.000) deliberately overshoots it by 4.078 mm so the boolean cuts clean
//  instead of leaving a skin, so a plain BOTTOM anchor would sit 4 mm too low.
//  "mouth" and "backstop" name slot_floor_y explicitly and are unaffected.
//
//  Usage -- BOSL2 body, pack entering through its FRONT face:
//
//      difference() {
//          cube([100, 120, 20], anchor = FRONT + BOTTOM);
//          dewalt_20v_negative(anchor = "mouth");
//      }
//
//  The pocket's mating face lands on the body's underside (Z = 0) and its mouth
//  on the body's front face (Y = 0); the pack seats toward +Y, into the body.
//  If your body's front-bottom-centre is elsewhere, one translate() puts it
//  there -- no arithmetic on your side.
//
//  Full list: "step" (the STEP origin point) "mouth" "backstop" "deck"
//             "latch-face" "terminal-l" "terminal-r"
// -----------------------------------------------------------------------------

module dewalt_20v_negative(clearance = clearance,
                           anchor = "step", spin = 0, orient = UP) {
    c   = clearance;
    c45 = c * sqrt(2);                                  // for 45 deg faces
    cr  = c * sqrt(1 + latch_ramp_slope * latch_ramp_slope);

    zb = back_stop_z     - c;
    zf = front_extend_z;
    xs = slot_half_x     + c;
    xm = rail_mid_half_x + c;
    xr = rail_half_x     + c;
    yt = rail_top_y      + c;

    // ---- bounding box, computed (it moves with the TUNE values) -------------
    // Extents are worked out in the measurement frame, then mapped to the
    // emitted Z-up frame by _zup(): [x, y, z] -> [x, -z, y].
    _ch   = max(entry_chamfer, 0);
    _xmax = xr + _ch;
    _ymin = bottom_extend_y;
    _ymax = max(latch_top_y + c,
                rail_top_y + _ch,
                terminal_bore ? terminal_bore_top_y : terminal_slot_top_y);

    _size = [2 * _xmax, zf - zb, _ymax - _ymin];        // X, Y=length, Z=height
    _cen  = [0, -(zb + zf) / 2, (_ymin + _ymax) / 2];   // centre, Z-up frame
    _tz   = (terminal_zone_z[0] + terminal_zone_z[1]) / 2;

    _anchors = [
        named_anchor("step",       _zup([0, 0, 0])                       - _cen, UP,    0),
        named_anchor("mouth",      _zup([0, slot_floor_y, entry_face_z]) - _cen, DOWN,  0),
        named_anchor("backstop",   _zup([0, slot_floor_y, back_stop_z])  - _cen, DOWN,  0),
        named_anchor("deck",       _zup([0, rail_top_y, _tz])            - _cen, UP,    0),
        named_anchor("latch-face", _zup([0, rail_top_y, latch_face_z])   - _cen, FRONT, 0),
        named_anchor("terminal-l", _zup([-abs(terminal_slot_x[0]),
                                    terminal_slot_top_y, _tz])           - _cen, UP,    0),
        named_anchor("terminal-r", _zup([ abs(terminal_slot_x[0]),
                                    terminal_slot_top_y, _tz])           - _cen, UP,    0),
    ];

    attachable(anchor, spin, orient, size = _size, anchors = _anchors) {
    translate(-_cen) rot([90, 0, 0]) union() {
        // ---- rail band -----------------------------------------------------
        // Plan profile, back to front: narrow nose, 45 deg widening, step out
        // to full flange width, then straight out the front.
        _band([
            [xs, zb                  ],
            [xs, rail_nose_back_z  - c],
            [xm, rail_nose_front_z - c],
            [xm, rail_step_z       - c],
            [xr, rail_step_z       - c],
            [xr, zf                  ],
        ], rail_floor_y - c, yt);

        // ---- lower slot ----------------------------------------------------
        _band([
            [xs, zb                ],
            [xs, flare_front_z - c],
            [xr, flare_front_z - c],
            [xr, zf                ],
        ], bottom_extend_y, rail_floor_y + c);

        // ---- lower-slot mouth chamfer --------------------------------------
        // Flares only at the bottom of the neck, and only over this Z window.
        if (lead_in) {
            cy = chamfer_start_y + c45 - c;   // meets the band flush
            d  = cy - slot_floor_y;
            translate([0, 0, flare_back_z - c])
                linear_extrude(flare_front_z - flare_back_z + c)
                    polygon([
                        [-xs,     cy             ],
                        [ xs,     cy             ],
                        [ xs + d, slot_floor_y   ],
                        [ xs + d, bottom_extend_y],
                        [-xs - d, bottom_extend_y],
                        [-xs - d, slot_floor_y   ],
                    ]);

            // Ramp easing the neck out to full flange width under the flange.
            cm = c * sqrt(1 + mouth_ramp_slope * mouth_ramp_slope);
            ey = mouth_ramp_end_y - c;
            translate([-xr, 0, 0])
                rot([90, 0, 90])
                    linear_extrude(2 * xr)
                        polygon([
                            [rail_floor_y + c, mouth_ramp_top_z - cm],
                            [rail_floor_y + c, flare_front_z        ],
                            [ey,               flare_front_z        ],
                            [ey, mouth_ramp_top_z - cm
                                 + mouth_ramp_slope * (rail_floor_y + c - ey)],
                        ]);
        }

        // ---- terminal blades -----------------------------------------------
        // Rooted down at rail_floor_y so they are solidly embedded in the rail
        // band rather than merely touching it on a coincident face.
        for (tx = terminal_slot_x)
            translate([tx,
                       (rail_floor_y + terminal_slot_top_y) / 2,
                       (terminal_zone_z[0] + terminal_zone_z[1]) / 2])
                cuboid([terminal_slot_w + 2 * c,
                        terminal_slot_top_y - rail_floor_y + 2 * c,
                        terminal_zone_z[1] - terminal_zone_z[0] + 2 * c]);

        // ---- latch catch ----------------------------------------------------
        _latch(c, c45, cr);

        // ---- ADDED: spade-terminal / wire bores -----------------------------
        // Starts at terminal_slot_top_y so the slat below it survives intact.
        if (terminal_bore)
            for (tx = terminal_slot_x)
                translate([tx, terminal_slot_top_y,
                           (terminal_zone_z[0] + terminal_zone_z[1]) / 2])
                    rot([-90, 0, 0])
                        cylinder(h = terminal_bore_top_y - terminal_slot_top_y,
                                 d = terminal_bore_d + 2 * c, $fn = 64);

        // ---- ADDED: 45 deg insertion lead-in at the mouth --------------------
        // Forward of entry_face_z the pocket is simply oversized by the chamfer.
        if (entry_chamfer > 0) {
            ch = entry_chamfer;
            yc = (rail_top_y + bottom_extend_y) / 2;
            h0 = rail_top_y - bottom_extend_y;

            translate([0, yc, entry_face_z - ch])
                prismoid(size1 = [2 * xr,        h0     ],
                         size2 = [2 * (xr + ch), h0 + ch],
                         h = ch, shift = [0, ch / 2], anchor = BOTTOM);

            translate([0, yc + ch / 2, (entry_face_z + zf) / 2])
                cuboid([2 * (xr + ch), h0 + ch, zf - entry_face_z]);
        }
    }
        children();
    }
}

// -----------------------------------------------------------------------------
//  helpers
// -----------------------------------------------------------------------------

// Map a point from the measurement frame (Y-up, STEP) to the emitted Z-up
// frame. Must stay in step with the rot([90,0,0]) applied to the geometry.
function _zup(p) = [p[0], -p[2], p[1]];

// Extrude a plan-view (X,Z) half-profile, mirrored about X = 0, between two Y.
// rot([-90,0,0]) maps the extrusion axis to +Y and the profile to the XZ plane.
module _band(half_profile, y0, y1) {
    pts = concat(
        half_profile,
        [for (i = [len(half_profile) - 1 : -1 : 0])
            [-half_profile[i][0], half_profile[i][1]]]
    );
    translate([0, y0, 0])
        rot([-90, 0, 0])
            linear_extrude(y1 - y0)
                polygon([for (p = pts) [p[0], -p[1]]]);
}

// Latch catch. Profile drawn in (Y,Z); rot([90,0,90]) maps the extrusion axis
// to +X, the profile's first axis to +Y and its second to +Z. Rooted at
// rail_floor_y so it is embedded in the rail band, not merely abutting it.
module _latch(c, c45, cr) {
    zback = latch_back_z  - c;
    zface = latch_face_z  + c;
    ytop  = latch_top_y   + c;

    ry0 = latch_ramp_start_y + (cr - c) / latch_ramp_slope;  // ramp leaves wall
    fy0 = latch_face_top_y   + (c45 - c);                    // face starts chamfer

    z_ramp_top = latch_back_z - cr + latch_ramp_slope * (ytop - latch_ramp_start_y);
    z_face_top = latch_face_z + c45 - latch_face_slope * (ytop - latch_face_top_y);

    translate([-latch_half_x - c, 0, 0])
        rot([90, 0, 90])
            linear_extrude(2 * (latch_half_x + c))
                polygon([
                    [rail_floor_y, zback     ],
                    [rail_floor_y, zface     ],
                    [fy0,          zface     ],
                    [ytop,         z_face_top],
                    [ytop,         z_ramp_top],
                    [ry0,          zback     ],
                ]);
}

// =============================================================================
//  No top-level geometry below this line -- on purpose.
//
//  This file is meant to live in your OpenSCAD library folder and be pulled in
//  with `include <dewalt_20v_negative.scad>`. `include` executes the file, so
//  ANY top-level geometry here would be injected into every model that
//  includes it. (`use` would avoid that, but `use` does not import top-level
//  variables, so the whole TUNE block would arrive as undef and the module
//  would render nothing. include is the only workable option, hence this rule.)
//
//  The demo/test body that used to sit here now lives in demo.scad.
// =============================================================================
