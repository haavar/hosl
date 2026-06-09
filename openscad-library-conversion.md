# Converting OpenSCAD Files to Libraries

A guide for turning standalone `.scad` files into reusable libraries, based on the pattern used in `rugged-box-library.scad` and `Dose library.scad`.

---

## Why bother?

A standalone `.scad` file renders geometry at the top level — you have to copy and edit the file for every new variant. A library file contains only module and function definitions. You import it with `use` and configure it by calling a module with arguments, so one file serves all variants.

---

## The pattern

Every library follows the same four-layer structure:

```
1. Header comment       — title, author, original source, license, usage example
2. Setup module         — accepts all parameters, sets $-prefixed special variables
3. Public part modules  — thin wrappers that call internal modules
4. Internal modules     — prefixed with _, do the actual geometry work
```

### Why `$`-prefixed variables?

OpenSCAD's `$variable` syntax creates a *special variable* that is visible to all children and descendants of the module that sets it. This is how parameters set in the setup module (`dose(...)`, `rbox(...)`) flow down to every internal module without having to pass them as arguments everywhere.

Normal variables assigned inside a module are not visible to children. `$variables` are.

---

## Step-by-step conversion

### 1. Identify the parameters

Find all top-level variables that control the shape. These become arguments to the setup module with their current values as defaults.

```scad
// Before — top-level globals
Breite_Dose = 13;
Hoehe_Dose  = 122;
Wanddicke   = 2;
```

```scad
// After — setup module arguments
module dose(
    inner_diameter = 13,
    inner_height   = 122,
    wall_thickness = 2
) { ... }
```

### 2. Identify derived/computed values

Any value calculated from parameters (e.g. `thread_thickness = thread_height / turns / 2`) becomes a `$variable` set inside the setup module, not a top-level assignment.

```scad
module dose(...) {
    $d_inner_diameter = inner_diameter;   // mirror parameter into $var
    $d_thread_thick   = thread_height / thread_turns / 2;  // derived
    children();
}
```

### 3. Remove all top-level rendering code

Delete or comment out any top-level calls that produce geometry — `difference()`, `union()`, `cylinder()`, etc. that sit outside a module. The library file must produce no geometry when opened on its own.

Add `module __end_customizer_options__() { }` near the top. This prevents the library's internal variables from appearing in the OpenSCAD Customizer when the file is used as a library.

### 4. Convert rendering modules to use `$variables`

Replace references to global variables with their `$`-prefixed equivalents throughout all modules.

```scad
// Before
cylinder(r = Breite_Dose / 2 + Wanddicke, h = Hoehe_Dose);

// After
cylinder(r = $d_inner_diameter / 2 + $d_wall, h = $d_inner_height);
```

### 5. Create public part modules

Add thin public wrappers with clean names. These are what users call in their own files.

```scad
module dose_can() { _dose_can(); }
module dose_cap() { _dose_cap(); }
```

Rename the original geometry modules with a `_` prefix to mark them as internal.

### 6. Create a layout/part-selection module (optional but useful)

If the original file had logic for printing layout, section views, or part selection, wrap it in a `dose_part()` (or equivalent) module:

```scad
module dose_part(part="all", layout=true, section=false) {
    difference() {
        _dose_layout(part, layout);
        if (section) { ... }
    }
}
```

### 7. Add the header comment

```scad
/*
 * [Title]
 * [Library name]
 *
 * Based on "[Original title]"
 * by [Author name]
 * [Original URL]
 *
 * License: [License name]
 *
 * [One line describing what was adapted]
 *
 * Usage:
 *   use <MyLibrary.scad>
 *
 *   mylib(param=value) {
 *       mylib_part();
 *   }
 */
```

---

## Naming conventions

| Thing | Convention | Example |
|---|---|---|
| Setup module | lowercase, noun | `dose()`, `rbox()` |
| Public part modules | `libname_partname` | `dose_can()`, `rbox_top()` |
| Internal modules | `_` prefix | `_dose_can()`, `_box_sides()` |
| Internal functions | `_` prefix | `_compute_latch_count()` |
| Special variables | `$libprefix_name` | `$d_wall`, `$b_inner_width` |
| Internal constants | standalone | `tol = 0.05;` (inside module) |

Use a short prefix on `$variables` to avoid collisions when multiple libraries are used together (`$d_` for dose, `$b_` for box, etc.).

---

## Custom modifications in a project file

One of the main advantages of the library approach over copying files is that you can modify the shape in your project file without ever touching the library. The library stays clean and reusable; customizations live in the project.

### Add geometry

Anything placed inside the setup module alongside the part modules is rendered in the same coordinate space. Use this to add bosses, labels, or attachment features:

```scad
dose(inner_diameter=30, inner_height=50) {
    dose_can();

    // Add a keyring loop to the outside of the can
    translate([18, 0, 10])
    rotate([90, 0, 0])
    difference() {
        cylinder(r=4, h=3, center=true);
        cylinder(r=2.5, h=4, center=true);
    }
}
```

### Subtract geometry

Wrap the part module in a `difference()` to cut into the shape — add ventilation holes, a window, a cable pass-through, etc.:

```scad
dose(inner_diameter=30, inner_height=50) {
    difference() {
        dose_can();

        // Row of ventilation holes around the side
        for (a = [0:45:359])
            rotate([0, 0, a])
            translate([16, 0, 20])
            rotate([0, 90, 0])
            cylinder(r=1.5, h=10);
    }
}
```

### Swap parameters per variant

Because configuration is just a function call, you can define named presets without any copy-pasting:

```scad
module pill_box()   { dose(inner_diameter=20, inner_height=15); }
module spice_jar()  { dose(inner_diameter=40, inner_height=60, wall_thickness=3); }
module film_can()   { dose(inner_diameter=33, inner_height=55); }

// Print all three at once
pill_box()  { dose_can(); translate([35,  0, 0]) dose_cap(); }
spice_jar() { translate([0,  70, 0]) dose_part("all", layout=true); }
film_can()  { translate([0, 160, 0]) dose_part("all", layout=true); }
```

### What to consider exposing during conversion

When converting a file, think about what points of modification are useful and make them easy to reach:

- **Parameters** — any dimension that might reasonably vary between uses
- **Public helper modules** — e.g. a `dose_interior()` module that returns the hollow volume, so users can subtract custom inserts
- **Coordinate anchors** — document where the origin is (bottom-center, etc.) so users can position additions confidently

---

## Usage in a project file

```scad
use <Dose library.scad>

// Small container
dose(inner_diameter=20, inner_height=30) {
    dose_can();
    translate([40, 0, 0])
    dose_cap();
}

// Tall container, placed to the side
translate([0, 60, 0])
dose(inner_diameter=20, inner_height=80)
    dose_part("all", layout=true);
```

---

## `use` vs `include`

Most libraries should be imported with `use <library.scad>`. This imports module and function definitions without executing any top-level code.

However, if a library contains `import()` calls (for SVG or STL files), use `include <library.scad>` instead. OpenSCAD resolves `import()` paths relative to the file that *contains* the call. With `use`, that is the library file — so the SVG files would need to live alongside the library. With `include`, the library code is inlined into the project file, so `import()` paths resolve relative to the project file, which is where the assets live.

```scad
// For libraries with import() calls (e.g. SVG-based dice):
include <dice.scad>

// For libraries without import() calls:
use <dose.scad>
use <project-box.scad>
```

Note this in the library's header comment so users know which to use.

---

## Finding attribution

When converting a file that was downloaded from the internet:

1. Search Thingiverse and Printables for distinctive variable names, comments, or phrases from the source file
2. Check for author credits already in the file (e.g. `// by Philipp Klostermann`)
3. Once found, record: original URL, author name, and license
4. Thingiverse blocks automated access — visit the page directly to read the license badge

License line format: `Creative Commons - Attribution (CC BY)`, `CC BY-SA`, `CC BY-NC`, etc.

---

## Checklist

- [ ] All top-level rendering code removed
- [ ] `module __end_customizer_options__() { }` added near top
- [ ] Parameters moved to setup module arguments with defaults
- [ ] Derived values computed inside setup module as `$variables`
- [ ] All geometry modules updated to use `$variables`
- [ ] Geometry modules renamed with `_` prefix
- [ ] Public wrapper modules added
- [ ] Header comment with title, author, URL, and license added
- [ ] File produces no geometry when opened on its own (test in OpenSCAD)
- [ ] If the library uses `import()` (SVG/STL): documented as `include`, not `use`
- [ ] A project file importing the library works as expected
