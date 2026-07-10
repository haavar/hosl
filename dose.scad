/*
 * Parametric Round Container with Threaded Cap
 * Dose Library
 *
 * Based on "Customizable Round Box with Threaded Lid"
 * by FaberUnserzeit (Philipp Klostermann)
 * https://www.thingiverse.com/thing:1648580
 *
 * The screw_extrude algorithm is by Philipp Klostermann
 * http://en.openscad.philipp-klostermann.de/
 *
 * License: Creative Commons - Attribution (CC BY)
 *
 * Adapted into a reusable library — original geometry preserved.
 *
 * Usage:
 *   use <Dose library.scad>
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
 */

module __end_customizer_options__() { }

/*
 * Main setup module
 *
 * Use this module to configure container sizing before rendering a part.
 *
 * Arguments:
 *  - inner_diameter:      Inner diameter of the container in mm
 *  - inner_height:        Inner height of the container in mm
 *  - wall_thickness:      Thickness of the container walls
 *  - cap_wall_thickness:  Thickness of the cap walls
 *  - floor_thickness:     Thickness of the floor
 *  - rim_height:          Height of an optional interior rim near the top
 *  - rim_diameter:        Diameter of the optional interior rim
 *  - thread_height:       Total height of the thread section
 *  - thread_turns:        Number of thread turns
 *  - cut_thread_percent:  How much (percent) to blunt the thread tips for easier assembly
 *  - smooth_sides:        Widen the thread base to smoothly match the cap
 *  - corner_radius:       Fillet radius for the closed outer edges (cap top, can bottom).
 *                         Set to 0 for sharp corners. Should not exceed wall_thickness,
 *                         cap_wall_thickness, or floor_thickness.
 *  - fn:                  Circle resolution in steps per 360°
 *  - fit_tolerance:       Gap between mating parts (printer dependent)
 *
 * Example:
 *
 *      dose(inner_diameter=30, inner_height=50) {
 *          // Render can
 *          dose_can();
 *
 *          // Render cap, placed beside the can for printing
 *          translate([50, 0, 0])
 *          dose_cap();
 *      }
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
    $d_inner_diameter  = inner_diameter;
    $d_inner_height    = inner_height;
    $d_wall            = wall_thickness;
    $d_cap_wall        = cap_wall_thickness;
    $d_floor           = floor_thickness;
    $d_rim_height      = rim_height;
    $d_rim_diameter    = rim_diameter;
    $d_thread_height   = thread_height;
    $d_thread_turns    = thread_turns;
    $d_cut_pct         = cut_thread_percent;
    $d_smooth_sides    = smooth_sides;
    $d_corner_radius   = corner_radius;
    $d_fn              = fn;
    $d_fit             = fit_tolerance;

    // Derived thread geometry
    $d_thread_thick = (thread_height / thread_turns) / 2;
    $d_coil_height  = thread_height / thread_turns;
    $d_cut_mid      = (thread_height / thread_turns / 2) * cut_thread_percent / 100;
    $d_cut_width    = (thread_height / thread_turns / 2) * (100 - cut_thread_percent) / 100;

    children();
}

// Public part modules

module dose_can() {
    _dose_can();
}

module dose_cap() {
    _dose_cap();
}

/*
 * Render a part by name with optional layout and section view
 *
 * Arguments:
 *  - part:           Which part(s) to render: "all", "can", or "cap"
 *  - layout:         If true, lay parts out side by side for printing
 *  - section:        If true, show a cross-section view
 *  - print_distance: Distance between parts when laid out side by side
 *
 * Example:
 *
 *      dose(inner_diameter=30, inner_height=50)
 *          dose_part("all", layout=true);
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
            translate([-$d_inner_diameter, 0, -0.05])
            cube([
                $d_inner_diameter * 2,
                $d_inner_diameter,
                $d_inner_height + $d_floor * 2 + $d_fit + 0.1
            ]);
        }
    }
}

// Internal modules

module _dose_layout(part, layout, print_distance) {
    if (part == "all" || part == "can") {
        _dose_can();
    }
    if (part == "all" || part == "cap") {
        translate([
            0,
            (layout && part == "all")
                ? -(
                    $d_inner_diameter
                    + $d_thread_thick * 2
                    + $d_wall * 2
                    + $d_cap_wall * 2
                    + print_distance
                  )
                : 0,
            layout
                ? 0
                : $d_inner_height + $d_floor * 2 + $d_fit / 2
        ])
        rotate([0, layout ? 0 : 180, 0])
        _dose_cap();
    }
}

module _dose_can() {
    tol = 0.05;

    difference() {
        union() {
            _dose_rounded_cylinder(
                r  = $d_inner_diameter / 2 + $d_wall,
                h  = $d_inner_height + $d_floor,
                cr = $d_corner_radius,
                round_bottom = true
            );

            // Exterior thread
            translate([0, 0,
                $d_inner_height + $d_floor - $d_thread_height - $d_coil_height / 2
            ])
            _dose_screw_extrude(
                P  = ($d_cut_pct > 0)
                    ? [
                        [-tol,          $d_thread_thick - tol],
                        [$d_cut_width,  $d_cut_mid           ],
                        [$d_cut_width, -$d_cut_mid           ],
                        [-tol,         -($d_thread_thick - tol)]
                      ]
                    : [
                        [-tol,          $d_thread_thick - tol],
                        [$d_thread_thick, 0                  ],
                        [-tol,         -($d_thread_thick - tol)]
                      ],
                r  = $d_inner_diameter / 2 + $d_wall,
                p  = $d_coil_height,
                d  = 360 * $d_thread_turns,
                sr = 0,
                er = 45,
                fn = $d_fn
            );

            // Thread base collar and support chamfer
            translate([0, 0,
                $d_inner_height + $d_floor - $d_thread_height - $d_coil_height
            ]) {
                cylinder(
                    r  = $d_inner_diameter / 2
                         + $d_thread_thick
                         + $d_wall
                         + ($d_smooth_sides ? $d_cap_wall : 0),
                    h  = $d_coil_height,
                    $fn = $d_fn
                );
                translate([0, 0, -$d_wall * 2])
                _dose_side_support(
                    $d_inner_diameter / 2 + $d_wall,
                    $d_thread_thick + ($d_smooth_sides ? $d_cap_wall : 0),
                    $d_wall * 2
                );
            }
        }

        // Interior hollow (rounded at the floor for a filleted inside corner)
        translate([0, 0, $d_floor])
        _dose_rounded_cylinder(
            r  = $d_inner_diameter / 2,
            h  = $d_inner_height + tol,
            cr = $d_corner_radius,
            round_bottom = true
        );

        // Interior rim clearance
        translate([0, 0, $d_floor + $d_inner_height - $d_rim_height])
        cylinder(
            r   = $d_rim_diameter / 2,
            h   = $d_rim_height + tol,
            $fn = $d_fn
        );

        // Trim thread above top face
        translate([0, 0, $d_inner_height + $d_floor - tol])
        cylinder(
            r = $d_inner_diameter + $d_wall * 2 + $d_thread_thick * 2 + tol,
            h = $d_coil_height * 2 + tol
        );
    }
}

module _dose_cap() {
    tol = 0.05;

    // Cap body with interior thread pocket
    difference() {
        _dose_rounded_cylinder(
            r  = $d_inner_diameter / 2
                 + $d_thread_thick
                 + $d_wall
                 + $d_cap_wall,
            h  = $d_thread_height + $d_floor,
            cr = $d_corner_radius,
            round_bottom = true
        );
        translate([0, 0, $d_floor])
        _dose_rounded_cylinder(
            r  = $d_inner_diameter / 2 + $d_wall + $d_thread_thick + $d_fit,
            h  = $d_thread_height + tol,
            cr = $d_corner_radius,
            round_bottom = true
        );
    }

    // Interior thread
    difference() {
        translate([0, 0, $d_floor - $d_coil_height / 2])
        _dose_screw_extrude(
            P  = ($d_cut_pct > 0)
                ? [
                    [tol * 2,          -($d_thread_thick - tol)],
                    [-$d_cut_width,    -$d_cut_mid             ],
                    [-$d_cut_width,     $d_cut_mid             ],
                    [tol * 2,           $d_thread_thick - tol  ]
                  ]
                : [
                    [tol,              -($d_thread_thick - tol)],
                    [-$d_thread_thick,  0                      ],
                    [tol,               $d_thread_thick - tol  ]
                  ],
            r  = $d_inner_diameter / 2 + $d_wall + $d_thread_thick + $d_fit,
            p  = $d_coil_height,
            d  = 360 * $d_thread_turns,
            sr = 0,
            er = 45,
            fn = $d_fn
        );

        // Trim thread above open end
        translate([0, 0, $d_thread_height + $d_floor])
        cylinder(
            r = $d_inner_diameter + $d_wall * 2 + $d_thread_thick + tol,
            h = $d_coil_height + tol
        );

        // Trim thread below floor
        rotate([180, 0, 0])
        translate([0, 0, -tol])
        cylinder(
            r = $d_inner_diameter + $d_wall * 2 + $d_thread_thick + tol,
            h = $d_coil_height + tol
        );
    }
}

module _dose_side_support(r, w, h) {
    rotate_extrude($fn = $d_fn)
    translate([r, 0, 0])
    polygon([[0, 0], [w, h], [0, h]]);
}

/*
 * Cylinder with optional fillets on the outer top/bottom edges.
 * round_bottom rounds the outer edge at z = 0.
 * round_top    rounds the outer edge at z = h.
 */
module _dose_rounded_cylinder(r, h, cr = 0, round_bottom = false, round_top = false) {
    if (cr <= 0 || (!round_bottom && !round_top)) {
        cylinder(r = r, h = h, $fn = $d_fn);
    } else {
        arc_steps = max(8, floor($d_fn / 4));
        bottom_arc = [
            for (i = [0 : arc_steps])
            let (a = 270 + (i / arc_steps) * 90)
            [(r - cr) + cr * cos(a), cr + cr * sin(a)]
        ];
        top_arc = [
            for (i = [0 : arc_steps])
            let (a = (i / arc_steps) * 90)
            [(r - cr) + cr * cos(a), (h - cr) + cr * sin(a)]
        ];
        profile = concat(
            [[0, 0]],
            round_bottom ? bottom_arc : [[r, 0]],
            round_top    ? top_arc    : [[r, h]],
            [[0, h]]
        );
        rotate_extrude($fn = $d_fn)
            polygon(profile);
    }
}

/**
 * _dose_screw_extrude(P, r, p, d, sr, er, fn)
 * Based on screw_extrude by Philipp Klostermann
 *
 * Sweeps polygon P along a helix:
 *  P  - cross-section polygon (points in clockwise order from outside)
 *  r  - helix radius (must exceed the most negative X in P)
 *  p  - pitch: mm of height per full turn
 *  d  - total rotation angle in degrees
 *  sr - ramp-in length in degrees
 *  er - ramp-out length in degrees
 *  fn - steps per 360°
 */
module _dose_screw_extrude(P, r, p, d, sr, er, fn) {
    anz_pt       = len(P);
    steps        = round(d * fn / 360);
    mm_per_deg   = p / 360;
    echo("steps: ", steps, " mm_per_deg: ", mm_per_deg);

    VL = [[r, 0, 0]];
    PL = [for (i = [0:1:anz_pt - 1]) [0, 1 + i, 1 + ((i + 1) % anz_pt)]];

    V = [
        for (n = [1:1:steps - 1])
        let (
            w1     = n * d / steps,
            h1     = mm_per_deg * w1,
            s1     = sin(w1),
            c1     = cos(w1),
            faktor = (w1 < sr)
                ? (w1 / sr)
                : ((w1 > (d - er))
                    ? 1 - ((w1 - (d - er)) / er)
                    : 1)
        )
        for (pt = P)
        [
            r * c1 + pt[0] * c1 * faktor,
            r * s1 + pt[0] * s1 * faktor,
            h1 + pt[1] * faktor
        ]
    ];

    P1 = [
        for (n = [0:1:steps - 3])
        for (i = [0:1:anz_pt - 1])
        [
            1 + (n * anz_pt) + i,
            1 + (n * anz_pt) + anz_pt + i,
            1 + (n * anz_pt) + anz_pt + (i + 1) % anz_pt
        ]
    ];

    P2 = [
        for (n = [0:1:steps - 3])
        for (i = [0:1:anz_pt - 1])
        [
            1 + (n * anz_pt) + i,
            1 + (n * anz_pt) + anz_pt + (i + 1) % anz_pt,
            1 + (n * anz_pt) + (i + 1) % anz_pt
        ]
    ];

    VR = [[r * cos(d), r * sin(d), mm_per_deg * d]];
    PR = [
        for (i = [0:1:anz_pt - 1])
        [
            1 + (steps - 1) * anz_pt,
            1 + (steps - 2) * anz_pt + ((i + 1) % anz_pt),
            1 + (steps - 2) * anz_pt + i
        ]
    ];

    convex = round(d / 45) + 4;
    echo("convexity = round(d/45)+4 = ", convex);
    polyhedron(concat(VL, V, VR), concat(PL, P1, P2, PR), convexity = convex);
}
