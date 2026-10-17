/*
 * Example: Gridfinity rugged case (WORK IN PROGRESS, not test-printed)
 *
 * Exposes every option of grugged(), which forwards to rbox() and
 * rbox_size_adjustments() in rugged-box-library.scad.
 *
 * Open in OpenSCAD and pick a Part, or export from the CLI, e.g.:
 *   OpenSCAD --backend=manifold -D 'Part="bottom"' -o base.stl gridfinity-rugged-box-example.scad
 */

include <hosl/gridfinity-rugged-box.scad>;

/* [Rendering] */
Part = "assembled_open"; // ["bottom": Bottom, "top": Lid, "latch": Latch, "handle": Handle, "label": Label, "side-by-side": Lid and base side-by-side, "assembled_open": Assembled open, "assembled_closed": Assembled closed]

/* [Gridfinity size] */
// Footprint width in Gridfinity cells (42 mm each)
Grid_X = 8; // [1:1:8]
// Footprint depth in Gridfinity cells
Grid_Y = 8; // [1:1:8]
// Usable bin height in 7 mm units
Grid_Z = 9; // [1:1:21]
// Gridfinity foot pockets in the base and bin-top blocks in the lid
Grid = true;

/* [Features] */
// Type or shape of seal to use, if desired
Lip_Seal_Type = "wedge"; // [none: None, wedge: Wedge ▽, square: Square □, "filament-1.75mm": 1.75mm Filament ○]
// Make the corners as thick as the box lip
Reinforced_Corners = false;
// Latch style
Latch_Type = "draw"; // [clip: Clip, draw: Draw]
// Number of latches (0 chooses automatically from the width)
Latch_Count = 0; // [0:1:2]
// Add a front grip to the box top (for boxes with two latches)
Top_Grip = false;
// Add end stops to the hinges on the box bottom
Hinge_End_Stops = false;
// Handle. Needs two latches and a base about 7U or taller.
Handle = true;
// Label. Needs two latches and enough room on the front.
Label = true;
// Custom text for the label
Label_Text = "Screws";
// Approximate height of the label text in millimeters
Label_Text_Size = 10; // [5:0.1:25]

/* [Shape] */
// Interior corner radius in millimeters. Keep at or below 4 so bins fit.
Corner_Radius = 3.5; // [0:0.1:4]
// Proportion of Corner Radius to chamfer outer top and bottom edges
Edge_Chamfer_Proportion = 0.4; // [0:0.1:1]

/* [Advanced Size Adjustments] */
// Base wall thickness in millimeters for most of the box
Wall_Thickness = 2.4; // [0.4:0.1:10]
// Thickness in millimeters to add to the wall thickness for the box lip
Lip_Thickness = 1.86; // [0.4:0.01:10]
// Base thickness in millimeters of the support ribs
Rib_Width = 4.0; // [1:0.1:20]
// Latch width in millimeters
Latch_Width = 22; // [5:1:50]
// Distance in millimeters between the latch hinge and catch screws
Latch_Screw_Separation = 20; // [5:1:40]
// Width in millimeters subtracted from latches for fit
Size_Tolerance = 0.05; // [0:0.01:1]

module __end_customizer_options__() { }

grugged(
    Grid_X, Grid_Y, Grid_Z,
    part = Part,
    grid = Grid,
    corner_radius = Corner_Radius,
    edge_chamfer_proportion = Edge_Chamfer_Proportion,
    lip_seal_type = Lip_Seal_Type,
    reinforced_corners = Reinforced_Corners,
    latch_type = Latch_Type,
    latch_count = Latch_Count,
    top_grip = Top_Grip,
    hinge_end_stops = Hinge_End_Stops,
    handle = Handle,
    label = Label,
    label_text = Label_Text,
    label_text_size = Label_Text_Size,
    wall_thickness = Wall_Thickness,
    lip_thickness = Lip_Thickness,
    rib_width = Rib_Width,
    latch_width = Latch_Width,
    latch_screw_separation = Latch_Screw_Separation,
    size_tolerance = Size_Tolerance
);
