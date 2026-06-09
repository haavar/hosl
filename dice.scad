/*
 * Custom Tabletop Dice Library
 * hosl
 *
 * Based on "Custom Tabletop Dice Generator V2.2"
 * by Lerch (https://github.com/Lerch4)
 * https://makerworld.com/en/models/739273
 * License: Standard Digital License
 *
 * Adapted into a reusable library with per-die-type modules.
 * Original geometry and algorithms preserved.
 *
 * Requires BOSL2: https://github.com/BelfrySCAD/BOSL2
 *
 * Use `include` (not `use`) in project files. This is required because
 * OpenSCAD resolves import() paths relative to the file that contains the
 * call. With `include`, that is the project file, so SVG paths resolve
 * correctly relative to the project file's directory.
 *
 *   include <dice.scad>
 *
 * Usage:
 *
 *   d8(
 *       diameter   = 35,
 *       die_color  = "pink",
 *       graphic_color = "black",
 *       faces = [
 *           face(svg="icon-a.svg", scale=0.06),          // face 1
 *           face(svg="icon-b.svg", offset=[-1.5, 0]),    // face 2
 *           face(svg="icon-c.svg"),                       // face 3
 *           face(svg="icon-d.svg", scale=0.07),           // face 4
 *           face(svg="icon-d.svg", scale=0.07),           // face 5
 *           face(svg="icon-c.svg"),                       // face 6
 *           face(svg="icon-b.svg", offset=[-1.5, 0]),    // face 7
 *           face(svg="icon-a.svg", scale=0.06),           // face 8
 *       ]
 *   );
 *
 *   // Numbered die with default text:
 *   d20(diameter=30, die_color="red");
 *
 *   // Default SVG on all faces, with one override:
 *   d12(die_color="red", graphic_color="white",
 *       default_svg="icon-a.svg", default_svg_scale=0.04,
 *       faces=[face(svg="icon-b.svg")]);
 */

include <BOSL2/std.scad>
include <BOSL2/polyhedra.scad>
include <BOSL2/fnliterals.scad>

module __end_customizer_options__() { }

// Face descriptor field indices (internal)
_DC_GTYPE      = 0; // "svg" or "text"
_DC_SVG        = 1; // svg file path
_DC_SCALE      = 2; // svg scale (0 = use default_svg_scale)
_DC_OFFSET     = 3; // [x, y] position offset
_DC_ROTATION   = 4; // rotation in degrees
_DC_TEXT       = 5; // text content ("default" = standard die numbering)
_DC_TEXT_SIZE  = 6; // text size (0 = use default_text_size)
_DC_FONT       = 7; // font name ("default" = use default_font)
_DC_FONT_STYLE = 8; // font style ("default" = use default_font_style)

/*
 * Create a face descriptor for use in the faces[] parameter.
 *
 * If svg is provided the face shows an SVG graphic.
 * If svg is empty the face shows text (standard numbering by default).
 * faces[] is indexed by face value: faces[0] configures the face showing "1",
 * faces[1] configures the face showing "2", and so on.
 *
 * Arguments:
 *  - svg:        SVG file path
 *  - scale:      SVG scale (0 = use die's default_svg_scale)
 *  - offset:     [x, y] position adjustment
 *  - rotation:   Rotation in degrees
 *  - text:       Text to display ("default" = standard die numbering)
 *  - text_size:  Text size (0 = use die's default_text_size)
 *  - font:       Font name ("default" = use die's default_font)
 *  - font_style: Font style ("default" = use die's default_font_style)
 *
 * Examples:
 *
 *      face(svg="myface.svg", scale=0.07)
 *      face(svg="myface.svg", offset=[-1.5, 0])
 *      face(text="★", font="Arial")
 *      face()    // standard numbered face
 */
function face(
    svg        = "",
    scale      = 0,
    offset     = [0,0],
    rotation   = 0,
    text       = "default",
    text_size  = 0,
    font       = "default",
    font_style = "default"
) = [svg != "" ? "svg" : "text", svg, scale, offset, rotation, text, text_size, font, font_style];


// Convenience die modules --------------------------------------------------------------------
// These expose the most common options. For advanced options use dice() directly.

/*
 * 4-sided die (tetrahedron).
 * Each face displays three numbers at its edges, one for each visible vertex.
 */
module d4(
    diameter            = 30,
    rounding            = 1,
    die_color           = "#00a2ffff",
    graphic_color       = "#505050",
    graphic_type        = "flush",
    default_text_size   = 4.3,
    default_graphic_depth = 1,
    default_font        = "Lora",
    default_font_style  = "Bold",
    default_svg         = "",
    default_svg_scale   = 0.05,
    faces               = [],
    fn                  = 128,
    d4_separation_offset = 0,
    use_simple_d4_face  = false
) {
    dice("d4", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn,
        d4_separation_offset=d4_separation_offset, use_simple_d4_face=use_simple_d4_face);
}

/* 6-sided die (cube). */
module d6(
    diameter            = 30,
    rounding            = 1,
    die_color           = "#00a2ffff",
    graphic_color       = "#505050",
    graphic_type        = "flush",
    default_text_size   = 4.3,
    default_graphic_depth = 1,
    default_font        = "Lora",
    default_font_style  = "Bold",
    default_svg         = "",
    default_svg_scale   = 0.05,
    faces               = [],
    fn                  = 128,
    indicator_for_6_and_9 = false
) {
    dice("d6", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn,
        indicator_for_6_and_9=indicator_for_6_and_9);
}

/* 8-sided die (octahedron). */
module d8(
    diameter            = 30,
    rounding            = 1,
    die_color           = "#00a2ffff",
    graphic_color       = "#505050",
    graphic_type        = "flush",
    default_text_size   = 4.3,
    default_graphic_depth = 1,
    default_font        = "Lora",
    default_font_style  = "Bold",
    default_svg         = "",
    default_svg_scale   = 0.05,
    faces               = [],
    fn                  = 128
) {
    dice("d8", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn);
}

/*
 * 10-sided die (trapezohedron).
 * - d10_0_indexed:       Show 0–9 instead of 1–10
 * - d10_multiples_of_10: Show 00, 10, 20 … 90
 * - d10_height_ratio:    Shape proportions: 0.5, 0.66, or 0.75
 */
module d10(
    diameter            = 30,
    rounding            = 1,
    die_color           = "#00a2ffff",
    graphic_color       = "#505050",
    graphic_type        = "flush",
    default_text_size   = 4.3,
    default_graphic_depth = 1,
    default_font        = "Lora",
    default_font_style  = "Bold",
    default_svg         = "",
    default_svg_scale   = 0.05,
    faces               = [],
    fn                  = 128,
    d10_0_indexed       = true,
    d10_multiples_of_10 = false,
    d10_height_ratio    = 0.5,
    indicator_for_6_and_9 = false
) {
    dice("d10", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn,
        d10_0_indexed=d10_0_indexed, d10_multiples_of_10=d10_multiples_of_10,
        d10_height_ratio=d10_height_ratio, indicator_for_6_and_9=indicator_for_6_and_9);
}

/* 12-sided die (dodecahedron). */
module d12(
    diameter            = 30,
    rounding            = 1,
    die_color           = "#00a2ffff",
    graphic_color       = "#505050",
    graphic_type        = "flush",
    default_text_size   = 4.3,
    default_graphic_depth = 1,
    default_font        = "Lora",
    default_font_style  = "Bold",
    default_svg         = "",
    default_svg_scale   = 0.05,
    faces               = [],
    fn                  = 128,
    indicator_for_6_and_9 = false
) {
    dice("d12", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn,
        indicator_for_6_and_9=indicator_for_6_and_9);
}

/*
 * 20-sided die (icosahedron).
 * - numerically_balanced_d20: Use a layout where opposite faces sum to 21
 */
module d20(
    diameter              = 30,
    rounding              = 1,
    die_color             = "#00a2ffff",
    graphic_color         = "#505050",
    graphic_type          = "flush",
    default_text_size     = 4.3,
    default_graphic_depth = 1,
    default_font          = "Lora",
    default_font_style    = "Bold",
    default_svg           = "",
    default_svg_scale     = 0.05,
    faces                 = [],
    fn                    = 128,
    numerically_balanced_d20 = false,
    indicator_for_6_and_9    = false
) {
    dice("d20", diameter=diameter, rounding=rounding,
        die_color=die_color, graphic_color=graphic_color, graphic_type=graphic_type,
        default_text_size=default_text_size, default_graphic_depth=default_graphic_depth,
        default_font=default_font, default_font_style=default_font_style,
        default_svg=default_svg, default_svg_scale=default_svg_scale,
        faces=faces, fn=fn,
        numerically_balanced_d20=numerically_balanced_d20,
        indicator_for_6_and_9=indicator_for_6_and_9);
}


// Main setup and render module ---------------------------------------------------------------

/*
 * Main dice module. Use the d4/d6/d8/d10/d12/d20 wrappers for normal use.
 * Call this directly when you need advanced options not exposed by the wrappers.
 *
 * faces[] is indexed by face value (0-based): faces[0] = face showing "1", etc.
 * Faces not in the list use default_svg (or numbered text if default_svg is empty).
 *
 * Advanced arguments:
 *  - indicator_for_6_and_9:        Add a dot after 6 and 9 to distinguish them
 *  - offset_for_indicated_6_and_9: Horizontal shift of the indicator dot
 *  - d10_0_indexed:                d10 shows 0–9 instead of 1–10
 *  - d10_multiples_of_10:          d10 shows 00, 10, 20 … 90
 *  - d10_height_ratio:             d10 proportions: 0.5, 0.66, or 0.75
 *  - numerically_balanced_d20:     Opposite d20 faces sum to 21
 *  - cutout_scale:                 Scale of the cutout window shape
 *  - cutout_size_offset:           Size adjustment for cutout window shape
 *  - cutout_location_offset:       Position offset for cutout window shape
 *  - d4_separation_offset:         Adjust spacing of numbers on d4 faces
 *  - use_simple_d4_face:           Single centered number per d4 face
 *  - force_flush_fix:              Fix z-fighting on flush graphics
 *  - flush_fix_value:              Depth of flush fix adjustment
 */
module dice(
    die_type,
    diameter              = 30,
    rounding              = 1,
    die_color             = "#00a2ffff",
    graphic_color         = "#505050",
    graphic_type          = "flush",
    default_text_size     = 4.3,
    default_graphic_depth = 1,
    default_font          = "Lora",
    default_font_style    = "Bold",
    default_svg           = "",
    default_svg_scale     = 0.05,
    faces                 = [],
    fn                    = 128,
    indicator_for_6_and_9        = false,
    offset_for_indicated_6_and_9 = 0,
    d10_0_indexed                = true,
    d10_multiples_of_10          = false,
    d10_height_ratio             = 0.5,
    numerically_balanced_d20     = false,
    cutout_scale                 = 0.75,
    cutout_size_offset           = 0,
    cutout_location_offset       = [0,0],
    d4_separation_offset         = 0,
    use_simple_d4_face           = false,
    force_flush_fix              = false,
    flush_fix_value              = 0.0000001
) {
    $fn = $preview ? 32 : fn;

    // Geometry derived from die type
    _die_name =
        die_type == "d20" ? "icosahedron"  :
        die_type == "d12" ? "dodecahedron" :
        die_type == "d10" ? "trapezohedron":
        die_type == "d8"  ? "octahedron"   :
        die_type == "d6"  ? "cube"         :
        die_type == "d4"  ? "tetrahedron"  : undef;

    _standard_order =
        die_type == "d20" ? (numerically_balanced_d20
            ? [1,11,13,15,12,5,17,19,2,18,4,14,9,8,7,3,10,6,16,20]
            : [1,19,11,13,9,7,17,3,18,5,4,15,12,10,6,16,2,8,14,20]) :
        die_type == "d12" ? [1,4,6,5,11,10,3,2,9,8,12,7] :
        die_type == "d10" ? [1,5,8,7,2,3,10,9,6,4] :
        die_type == "d8"  ? [1,7,3,5,4,6,8,2] :
        die_type == "d6"  ? [1,3,2,4,6,5] :
        die_type == "d4"  ? [1,2,3,4] : undef;

    _d10_height    = diameter * d10_height_ratio;
    _diameter_true = in_list(die_type, ["d8","d10","d12","d20","d4"]) ? diameter/2 : diameter;

    _base_rotation =
        (die_type == "d10") ? (
            d10_height_ratio == 0.5  ? [25.5,-25.5,-115.5,-25.5,-115.5,-115.5,25.5,-115.5,-25,-25.5]  :
            d10_height_ratio == 0.75 ? [32.5,-32.5,-110.5,-32.5,-110.5,-110.5,32.5,-110.5,-32.5,-32.5] :
                                       [30,-30,-112.5,-30,-112.5,-112.5,30,-112.5,-30,-30]
        ) :
        (die_type == "d8") ? [0,0,0,0,120,-120,-120,0] :
        repeat(0, 20);

    // Resolve per-face data from faces[] (index = face value - 1)
    _default_gtype = default_svg != "" ? "svg" : "text";

    _graphic_list    = [for (i=[0:19]) _dc_field(faces, i, _DC_GTYPE,      _default_gtype)];
    _svg_list        = [for (i=[0:19]) _dc_field(faces, i, _DC_SVG,        default_svg)];
    _scale_list      = [for (i=[0:19]) _dc_field(faces, i, _DC_SCALE,      0)];
    _offset_list     = [for (i=[0:19]) _dc_field(faces, i, _DC_OFFSET,     [0,0])];
    _rotation_list   = [for (i=[0:19]) _dc_field(faces, i, _DC_ROTATION,   0)];
    _text_list       = [for (i=[0:19]) _dc_field(faces, i, _DC_TEXT,       "default")];
    _text_size_list  = [for (i=[0:19]) _dc_field(faces, i, _DC_TEXT_SIZE,  0)];
    _font_list       = [for (i=[0:19]) _dc_field(faces, i, _DC_FONT,       "default")];
    _font_style_list = [for (i=[0:19]) _dc_field(faces, i, _DC_FONT_STYLE, "default")];

    // Pass all configuration down as special variables
    $dc_die           = die_type;
    $dc_die_name      = _die_name;
    $dc_diameter      = diameter;
    $dc_diameter_true = _diameter_true;
    $dc_rounding      = rounding;
    $dc_depth         = default_graphic_depth;
    $dc_graphic_type  = graphic_type;
    $dc_default_text_size  = default_text_size;
    $dc_default_font       = default_font;
    $dc_default_font_style = default_font_style;
    $dc_default_svg_scale  = default_svg_scale;
    $dc_standard_order     = _standard_order;
    $dc_base_rotation      = _base_rotation;
    $dc_d10_height         = _d10_height;
    $dc_d10_height_ratio   = d10_height_ratio;
    $dc_shape_faces   = die_type == "d10" ? 10 : undef;
    $dc_shape_height  = die_type == "d10" ? _d10_height : undef;
    $dc_rad_final     = in_list(die_type, ["d8","d10","d12","d20"]) ? _diameter_true : undef;
    $dc_mid_rad_final = die_type == "d4" ? _diameter_true : undef;
    $dc_sides_final   = in_list(die_type, ["d8","d10","d12","d20","d4"]) ? undef : _diameter_true;
    $dc_graphic_list    = _graphic_list;
    $dc_svg_list        = _svg_list;
    $dc_scale_list      = _scale_list;
    $dc_offset_list     = _offset_list;
    $dc_rotation_list   = _rotation_list;
    $dc_text_list       = _text_list;
    $dc_text_size_list  = _text_size_list;
    $dc_font_list       = _font_list;
    $dc_font_style_list = _font_style_list;
    $dc_indicator         = indicator_for_6_and_9;
    $dc_indicator_offset  = offset_for_indicated_6_and_9;
    $dc_d10_0_indexed     = d10_0_indexed;
    $dc_d10_multiples     = d10_multiples_of_10;
    $dc_cutout_scale      = cutout_scale;
    $dc_cutout_size_offset = cutout_size_offset;
    $dc_cutout_loc_offset = cutout_location_offset;
    $dc_d4_sep            = d4_separation_offset;
    $dc_simple_d4         = use_simple_d4_face;
    $dc_flush_fix_value   = flush_fix_value;

    // Render
    difference() {
        color(die_color)
            regular_polyhedron($dc_die_name, facedown=true,
                mr=$dc_mid_rad_final, r=$dc_rad_final, side=$dc_sides_final,
                repeat=true, draw=true, rounding=$dc_rounding,
                faces=$dc_shape_faces, height=$dc_shape_height, anchor=BOT);
        color(graphic_color)
        if (graphic_type != "embossed")
            _dc_graphics(cutout=true);
    }

    color(graphic_color) {
        if (graphic_type == "embossed")
            _dc_graphics();
        else if (graphic_type == "flush")
            _dc_graphics(flush_fix=force_flush_fix);
    }

    color(die_color)
    if (graphic_type == "cutout")
        _dc_graphics();
}


// Internal functions -------------------------------------------------------------------------

// Read one field from a face descriptor, returning fallback if the face or field is absent
function _dc_field(faces, i, field, fallback) =
    let(f = i < len(faces) ? faces[i] : undef)
    (f != undef && f[field] != undef) ? f[field] : fallback;

// Build the font string understood by OpenSCAD's text() module
function _dc_font_string(font, font_style, default_font, default_font_style) =
    let(
        style = (font_style == "default") ? default_font_style :
                in_list(font_style, ["None","none",""]) ? "" : font_style,
        name  = in_list(font, ["None","none","","default"]) ? default_font : font
    )
    in_list(style, [""]) ? name : str(name, ":style=", style);

// Compute the final display text for a face, applying d10 and indicator adjustments
function _dc_final_text(face_value, face_index, standard_order,
                         d10_0_indexed, d10_multiples, die, indicator) =
    let(
        base   = in_list(downcase(face_value), ["default"])
                 ? str(standard_order[face_index]) : face_value,
        d10adj = (die == "d10")
                 ? (d10_multiples ? format_int(parse_int(base)*10, 2) :
                    (d10_0_indexed ? str(parse_int(base)-1) : base))
                 : base,
        indic  = (indicator && in_list(die, ["d20","d12","d10"]) && in_list(d10adj, ["6","9"]))
                 ? str_join([d10adj, "."]) : d10adj
    ) indic;

// Resolve text size, falling back to the die default if 0
function _dc_text_size(text_size, default_text_size) =
    text_size > 0 ? text_size : default_text_size;


// Internal modules ---------------------------------------------------------------------------

module _dc_graphics(cutout=false, flush_fix=false) {
    // BOSL2's regular_polyhedron repeats children across all faces via $faceindex.
    // We list the child module 20 times to cover up to d20.
    regular_polyhedron($dc_die_name, facedown=true,
        mr=$dc_mid_rad_final, r=$dc_rad_final, side=$dc_sides_final,
        repeat=true, draw=false, rounding=$dc_rounding,
        faces=$dc_shape_faces, height=$dc_shape_height, anchor=BOT) {
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
        _dc_determine_graphic(cutout, flush_fix);
    }
}

module _dc_determine_graphic(cutout=false, flush_fix=false) {
    face_idx  = $dc_standard_order[$faceindex] - 1;
    face_font = _dc_font_string(
        $dc_font_list[face_idx], $dc_font_style_list[face_idx],
        $dc_default_font, $dc_default_font_style
    );
    face_text = _dc_final_text(
        $dc_text_list[face_idx], $faceindex,
        $dc_standard_order, $dc_d10_0_indexed, $dc_d10_multiples,
        $dc_die, $dc_indicator
    );
    face_size     = _dc_text_size($dc_text_size_list[face_idx], $dc_default_text_size);
    depth         = $dc_depth;
    extruded_depth = flush_fix ? depth - $dc_flush_fix_value : depth;
    indicator_adj = ($dc_indicator
                     && in_list($dc_die, ["d20","d12","d10"])
                     && in_list(face_text, ["6.","9."]))
                    ? [$dc_indicator_offset, 0] : [0,0];

    down(depth)
    rotate($dc_base_rotation[$faceindex]) {
        if ($dc_graphic_type == "cutout" && cutout) {
            move($dc_cutout_loc_offset)
                _dc_cutout_shape();
        } else {
            linear_extrude(extruded_depth)
            move($dc_offset_list[face_idx] + indicator_adj)
            rotate($dc_rotation_list[face_idx]) {
                if ($dc_graphic_list[face_idx] == "text") {
                    if ($dc_die == "d4" && !$dc_simple_d4) {
                        _dc_d4_face_graphic();
                    } else {
                        text(face_text, size=face_size, anchor=CENTER,
                             font=face_font, valign="center", halign="center");
                    }
                } else {
                    scale($dc_scale_list[face_idx] > 0
                          ? $dc_scale_list[face_idx]
                          : $dc_default_svg_scale)
                        import($dc_svg_list[face_idx], center=true);
                }
            }
        }
    }
}

module _dc_cutout_shape() {
    depth = $dc_depth;
    if ($dc_die == "d20") {
        linear_extrude(depth)
            regular_ngon(n=3, d=$dc_diameter/2 + $dc_cutout_size_offset, spin=90);
    } else if ($dc_die == "d12") {
        linear_extrude(depth)
            regular_ngon(n=5, d=$dc_diameter/2 + $dc_cutout_size_offset, spin=90);
    } else if ($dc_die == "d8") {
        linear_extrude(depth)
            regular_ngon(n=3, d=$dc_diameter/1.75 + $dc_cutout_size_offset, spin=90);
    } else if ($dc_die == "d6") {
        linear_extrude(depth)
            regular_ngon(n=4, d=$dc_diameter + $dc_cutout_size_offset, spin=45);
    } else if ($dc_die == "d4") {
        linear_extrude(depth)
            regular_ngon(n=3, d=$dc_diameter + $dc_cutout_size_offset, spin=90);
    } else if ($dc_die == "d10") {
        adj = ($dc_d10_height_ratio == 0.5)  ? $dc_diameter/9  :
              ($dc_d10_height_ratio == 0.75) ? 0               : $dc_diameter/30;
        linear_extrude(depth)
        scale($dc_cutout_scale)
        rotate(270)
        projection(cut=true)
        up(-$dc_d10_height/75)
        left(adj)
            regular_polyhedron($dc_die_name, facedown=true, r=$dc_diameter/2,
                repeat=true, draw=true, rounding=$dc_rounding,
                faces=$dc_shape_faces, height=$dc_shape_height, anchor=BOT);
    }
}

// d4 faces show three numbers — one per edge, readable from each vertex
module _dc_d4_face_graphic() {
    top_num   = ($faceindex==0)?4:($faceindex==1)?1:($faceindex==2)?2:3;
    left_num  = ($faceindex==0)?2:($faceindex==1)?4:($faceindex==2)?4:2;
    right_num = ($faceindex==0)?3:($faceindex==1)?3:($faceindex==2)?1:1;

    function d4_text(n) =
        in_list(downcase($dc_text_list[n-1]), ["default"])
            ? str($dc_standard_order[n-1])
            : $dc_text_list[n-1];

    face_font = _dc_font_string("default", "default", $dc_default_font, $dc_default_font_style);
    face_size = _dc_text_size(0, $dc_default_text_size);

    rotate(-30)
    arc_copies(d=$dc_mid_rad_final + $dc_d4_sep, n=3, rot=true) {
        if      ($idx == 0) rotate(270) text(str(d4_text(top_num)),   size=face_size, anchor=CENTER, font=face_font, valign="center", halign="center");
        else if ($idx == 1) rotate(270) text(str(d4_text(left_num)),  size=face_size, anchor=CENTER, font=face_font, valign="center", halign="center");
        else if ($idx == 2) rotate(270) text(str(d4_text(right_num)), size=face_size, anchor=CENTER, font=face_font, valign="center", halign="center");
    }
}
