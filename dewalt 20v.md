# DeWalt 20V negative — engineering notes

Working notes for `dewalt 20v.scad`. Written for whoever picks this up next
(probably you, or Claude, in six months). Covers where the numbers came from,
the things that are counter-intuitive, and how to check you haven't broken
anything.

**This document is the only surviving record.** The original working directory
(`~/Documents/dewalt 20v adapter/`) was deleted. Everything needed to keep
working on the library is in here — including the verification tooling and a
regression fixture baked out of the source geometry before it went.

```openscad
include <hosl/dewalt 20v.scad>     // note: space in the filename is fine
```

Lives at `~/github/hosl/dewalt 20v.scad`, symlinked into the OpenSCAD library
path as `~/Documents/OpenSCAD/libraries/hosl/`. Requires BOSL2 in the same
library folder.

---

## 1. What exists, and what was lost

**Survives:** the library, and this file.

**Deleted with the working directory:**

| Gone | What it was | Consequence |
|---|---|---|
| `dewalt_battery_dock_r0.step` | **Ground truth.** Third-party tool-side receptacle, "battery dock v7", Autodesk / ST-Developer, 2022-06-15. | No new dimension can ever be re-derived from source. |
| `battery_dock_lower.stl`, `battery_dock_upper.stl` | Tessellation of that STEP, ~13k triangles, exported on another machine. Every `EXACT` constant was bisected off these. | Full verification (§6) can no longer run. |
| `preview_overlay.scad`, `demo.scad`, `previews/*.png` | Working files. | Reproduced inline in §9 — no real loss. |

### Read this before trying to re-measure anything

The STEP was the source, but **this machine has no way to read it** — no
FreeCAD, gmsh, cadquery, OCP or trimesh, and no pip to install them. The STLs
existed only because they were exported elsewhere. So recovering the ability to
measure means *both* finding the STEP again *and* re-exporting it to STL
somewhere that has a CAD kernel.

What replaces it: §6 embeds a **regression fixture** — 320 sampled cross-section
lines through the real dock, capturing its solid boundaries around every
critical plane. That is enough to prove a change hasn't broken the fit, and it
is verified to catch errors as small as 0.3 mm in either direction. It is *not*
enough to derive a dimension that was never measured. If you need one of those,
you need the STEP back.

The prober and fixture are embedded in this file rather than shipped as separate
scripts, so this document stays self-contained.

---

## 2. Coordinate frames — there are two, on purpose

**Measurement frame** (Y-up) — what the STEP file uses and what every constant
in the TUNE block is written in, so each number maps 1:1 to a measured plane
with no transform to get wrong when re-checking it:

```
+X  width, symmetric about 0
+Y  height. Pack's top deck at Y = +0.500. Pack body hangs into -Y.
+Z  slide axis. Pack WITHDRAWS toward +Z, SEATS toward -Z.
    Terminals ~ Z -51.8, back stop Z -58.010.
```

**Emitted frame** (Z-up) — what actually comes out of the module. A single
`rot([90,0,0])` is applied at the end of `dewalt_20v_negative()`:

```
[x, y, z]  ->  [x, -z, y]          (helper: _zup() in the .scad)

+X  width (unchanged)
+Z  UP     — pack height, deck at Z = +0.500
-Y  FRONT  — the mouth. Pack withdraws toward FRONT, seats toward BACK.
```

### Why it's built this way

v1 emitted the raw measurement frame, reasoning that traceability mattered most.
That was wrong in practice: every BOSL2 body is Z-up, so the part came out
permanently 90° off and the caller had to write
`rotate([90,0,0]) dewalt_20v_negative(anchor="mouth")` — which defeats the
entire purpose of an anchor. Rotating *inside* costs nothing and keeps the
constants traceable, because the rotation lives in exactly one place.

**If you change that rotation, change `_zup()` to match.** The bounding box and
every named-anchor position are computed in the measurement frame and mapped
through `_zup()`; if the two drift apart, anchors silently land in the wrong
place while the geometry still looks fine. That is the nastiest possible bug
here, and nothing else in the file will catch it — the round-trip test in §6
exists specifically to.

A useful consequence: `rotate([-90,0,0]) dewalt_20v_negative(anchor="step")`
returns you to raw measurement-frame geometry, which is how the dock-comparison
tests in §6 work.

---

## 3. What the solid is (and what it deliberately is not)

It is the pack's **swept volume** — space the pack occupies *plus* space it
sweeps through on the way in. That is exactly the void inside the dock, which is
why differencing it reproduces the dock's pocket.

**Excluded on purpose:** the large cavity above Y = 1.5 in the terminal zone.
That is where the *tool's* contact block lives. It is tool-side volume, not pack
volume. Modelling it would gouge a hole through your adapter for nothing. If a
future you sees "missing" geometry there, this is why.

### Three findings that contradict the obvious reading

Worth re-reading before you "fix" something:

1. **The rail interface is a T-slot, not a channel.** ±22.331 and ±25.519 are
   *not* the two walls of a ~3.2 mm channel. They are the **same flange at two
   different Z stations** — full width in front of `rail_step_z`, stepped in
   behind it. At any given Z the rail-band void is one continuous span across
   the centreline. Cross-section is a 36.14-wide neck under a 51.04-wide flange.

2. **Two terminal blades, not five.** Exactly two openings pierce the Y = 0.500
   deck, at X = ±11.498 — B+ and B−. TH / ID / cell-balance are not broken out
   by this dock. `terminal_slot_x` is a list; add centres if you need them.

3. **The dock has no entry chamfer.** Its pocket walls run dead straight to the
   front face at ±25.519. The 45° lead-in in the .scad is an *addition*, not
   something recovered from the source.

---

## 4. Measured geometry

Every value tagged `EXACT` in the .scad was bisected off the mesh to ~1e-4 mm.
They are not eyeballed, and not rounded off a slicer readout.

### Envelope

| | Dock (source) | Negative (defaults) |
|---|---|---|
| X | −30.163 … +30.163 | ±26.719 (`rail_half_x` + `entry_chamfer`) |
| Y | −9.922 … +15.000 | −14.000 … +20.000 |
| Z | −73.055 … +12.170 | −58.010 … +14.000 |

The negative's Y/Z extremes are set by `bottom_extend_y`, `front_extend_z` and
`terminal_bore_top_y` — all arbitrary overruns chosen to cut clean through a
body. **They are not features.** This is why anchors name real planes instead of
using the bounding box (§5).

### Feature planes

**Lower slot (pack's neck)** — `slot_half_x` ±18.069, floor `slot_floor_y`
−9.922, back stop −58.010.

**Rail band (T-flange)** — `rail_floor_y` −5.072 to `rail_top_y` +0.500.
Plan half-width along Z, back → front:

| Z range | half-width |
|---|---|
| −58.010 … −51.307 | 18.069 |
| −51.307 … −47.045 | 45° ramp, 18.069 → 22.331 |
| −47.045 … −36.028 | 22.331 |
| −36.028 … front | 25.519 |

**Mouth reliefs** (two independent, neither fit-critical — both sit outside the
seated pack, they only open the entrance):
- 45° bottom-corner chamfer, Z −26.063 … −15.313, starting at Y −7.215,
  reaching half-width 20.776 at the floor.
- A ramp under the flange, `mouth_ramp_slope` = 1.8868 dZ per unit drop in Y,
  from Z −18.752 at `rail_floor_y` down to Y −6.418 where it meets −15.313.
  Sharp corner, no fillet — checked at 0.02 mm steps.

**Terminals** — slots X ±11.498, width 0.950, Z −55.010 … −48.510, through a
1.0 mm deck (Y 0.500 → 1.500).

**Latch catch** — X ±11.845, Y 0.500 → 5.330 (flat roof), Z −6.473 → +0.250.
Back is a cam ramp of slope **1.050** (not 45°) leaving the wall at Y 1.377.
Front is the **retention face** at Z +0.250 — the surface that stops the pack
pulling out — chamfering back at slope 1.000 above Y 4.549.

> The 1.050 ramp slope matters. An initial 45° assumption put the ramp 0.24 mm
> proud and produced the only real interference the verifier ever caught.

---

## 5. Anchors

Anchor points are *named* in the measurement frame but *emitted* in the Z-up
frame, so no `rotate()` is needed at the call site:

```openscad
difference() {
    cube([100, 120, 20], anchor = FRONT + BOTTOM);
    dewalt_20v_negative(anchor = "mouth");
}
```

The useful one is `"mouth"` = `(0, slot_floor_y, entry_face_z)`: centreline ×
mating face × entry face. Three planes that each mean something physically. It
puts the mating face on the body's underside (Z=0) and the mouth on the body's
front face (Y=0), with the pack seating toward +Y into the body.

`"step"` is now just *the point* that was the STEP origin — it no longer implies
the old output orientation. Others: `"backstop"`, `"deck"`, `"latch-face"`,
`"terminal-l"`, `"terminal-r"`.

Because the part is emitted Z-up, `UP`/`DOWN`/`FRONT`/`BACK` now mean what they
say — the mating face is `DOWN`, the mouth is `FRONT`. (Pre-rotation they were
scrambled; if you find old notes claiming the mouth faces `UP`, they predate
this.)

**`slot_floor_y` (−9.922) is the mating face** — your adapter's underside sits
on the pack's shoulder there, tongue protruding 10.42 mm up through it. It is
**not** the bottom of the solid; `bottom_extend_y` overshoots it by 4.078 mm.
A generic BOSL2 `BOTTOM` anchor lands 4 mm low. This is the single easiest
mistake to make here.

Others: `"backstop"`, `"deck"`, `"latch-face"`, `"terminal-l"`, `"terminal-r"`.

The bounding box passed to `attachable()` is **computed**, not hard-coded — it
moves with `clearance`, `entry_chamfer`, `terminal_bore_top_y`, and both extend
params. That expression is the most likely place for a future bug. Re-check it
(§6) after touching any of those.

---

## 6. Re-verifying after a change

Everything needed is embedded below — this file is the single source. Nothing to
install: the prober is stdlib-only Python (no numpy, no CAD kernel; the machine
this was built on had neither, and no pip either).

Verification needs the **ground-truth STLs**, so run it from the project folder,
not the OpenSCAD library folder (§8).

### What "correct" means

Two geometric properties, checked against the real dock:

- **Interference** — no part of the negative may overlap dock material. If it
  does, the pack physically will not go in.
- **Coverage** — every enclosed pocket span in the dock (for Y <= 0.45, the pack
  side) must be filled by the negative. If it isn't, your adapter keeps material
  where the pack needs to be.

Both must be **0 lines, 0.000 mm** with the added features off.

Plus a separate **anchor placement** check — and read this before deciding to
skip it:

> The geometry checks **cannot** catch `_zup()` drift. `_zup()` is linear, so it
> maps the origin to the origin, and the `"step"` anchor sits at the origin.
> `_zup()` can therefore be completely wrong while `anchor="step"` geometry still
> matches the dock perfectly. This is not theoretical: three different broken
> `_zup()` mappings were tried and **all three passed the fixture check**. Only
> the non-origin anchors expose it. That is what Step 4 is for.

And two spot checks: OpenSCAD reports `Genus: 0` for the bare module, and the
terminal slat survives — the negative must be a 0.950 mm slot at Y 0.6-1.45 and
a 7.000 mm circle above Y 1.55.

### Two modes

**Fixture mode — this is what you run.** The dock STLs are gone (§1), so
interference and coverage run against the fixture embedded in Step 2: 320
sampled cross-section lines through the real dock, chosen to straddle every
critical plane. Validated against twelve deliberate mutations (widths, floors,
step positions, chamfer starts) in both directions — all twelve caught, down to
0.3 mm, with no false failure on the correct library.

**Full mode — only if the STLs are ever restored.** Identical logic, but sweep
Y -9.85..5.32 step 0.125 and Z -57.75..11.9 step 0.25 against
`Solid(['battery_dock_lower.stl','battery_dock_upper.stl'])` instead of the
fixture (~23k lines, a few seconds). Strictly stronger; prefer it if available.

### Step 1 — the prober

Extract it (idempotent, safe to re-run):

```bash
sed -n '/^# meshprobe.py$/,/^# end meshprobe.py$/p' 'dewalt 20v.md' > meshprobe.py
```

```python
# meshprobe.py
# stdlib-only STL prober. No numpy, no CAD kernel, no installs -- the machine
# this was built on had none of them and no pip either.
# Loads binary or ASCII STL, then answers point-in-solid and face-position
# queries by ray casting along +X with triangles binned by Z.
#
#     from meshprobe import Solid
#     d = Solid(['some.stl'])
#     d.inside(x, y, z)   -> bool
#     d.xs(y, z)          -> sorted X crossings of the ray at (y,z)
#     d.bbox()            -> ((xlo,xhi),(ylo,yhi),(zlo,zhi))
#
# Two derived idioms do all the real work:
#
#   solid x-intervals at (y,z):
#       xs = s.xs(y,z); [(xs[i],xs[i+1]) for i in range(0,len(xs)-1,2)]
#
#   bisect a face to ~1e-4 mm: sample either side of it, then binary search on
#   s.inside() for 60 iterations. This is how every EXACT constant in the .scad
#   was obtained -- do not read numbers off a slicer or a screenshot.
import struct, math
from collections import defaultdict

def load(path):
    d=open(path,'rb').read()
    if d[:5]==b'solid' and b'facet' in d[:2000]:
        tris=[];cur=[]
        for line in d.decode('ascii','replace').splitlines():
            s=line.split()
            if s and s[0]=='vertex':
                cur.append((float(s[1]),float(s[2]),float(s[3])))
                if len(cur)==3: tris.append(tuple(cur)); cur=[]
        return tris
    n=struct.unpack('<I',d[80:84])[0]
    return [tuple(struct.unpack('<12f',d[84+i*50:84+i*50+48])[3:12][j:j+3] for j in (0,3,6)) for i in range(n)]

class Solid:
    def __init__(self, paths, zbin=1.0):
        self.tris=[]
        for p in paths: self.tris+=load(p)
        self.zb=zbin; self.bins=defaultdict(list)
        for t in self.tris:
            zs=[p[2] for p in t]
            for b in range(int(math.floor(min(zs)/zbin)), int(math.floor(max(zs)/zbin))+1):
                self.bins[b].append(t)
    def xs(self,y,z):
        out=[]
        for (a,b,c) in self.bins[int(math.floor(z/self.zb))]:
            ay,az=a[1],a[2]; by,bz=b[1],b[2]; cy,cz=c[1],c[2]
            d=(bz-cz)*(ay-cy)+(cy-by)*(az-cz)
            if abs(d)<1e-12: continue
            l1=((bz-cz)*(y-cy)+(cy-by)*(z-cz))/d
            l2=((cz-az)*(y-cy)+(ay-cy)*(z-cz))/d
            l3=1-l1-l2
            if l1<-1e-9 or l2<-1e-9 or l3<-1e-9: continue
            out.append(l1*a[0]+l2*b[0]+l3*c[0])
        out.sort()
        ded=[]
        for v in out:
            if not ded or abs(v-ded[-1])>1e-7: ded.append(v)
        return ded
    def inside(self,x,y,z):
        return sum(1 for v in self.xs(y,z) if v>x)%2==1
    def bbox(self):
        xs=[p[0] for t in self.tris for p in t]; ys=[p[1] for t in self.tris for p in t]; zs=[p[2] for t in self.tris for p in t]
        return (min(xs),max(xs)),(min(ys),max(ys)),(min(zs),max(zs))
# end meshprobe.py
```

### Step 2 — the dock fixture

This is the irreplaceable part: the real dock's solid boundaries, sampled before
the STLs were deleted. Format is `y z x0,x1,x2,x3,...` in the **measurement**
frame, where each pair is one solid span in X. `-` means no material on that line.

```bash
sed -n '/^# dock_fixture.txt$/,/^# end dock_fixture.txt$/p' 'dewalt 20v.md' > dock_fixture.txt
```

```
# dock_fixture.txt
-9.8 -58.3 -29.637,29.637
-9.8 -57.7 -29.637,-18.069,18.069,29.637
-9.8 -55.2 -29.637,-18.069,18.069,29.637
-9.8 -54.8 -29.637,-18.069,18.069,29.637
-9.8 -51.5 -29.637,-18.069,18.069,29.637
-9.8 -50 -29.637,-18.069,18.069,29.637
-9.8 -49 -29.637,-18.069,18.069,29.637
-9.8 -48.3 -29.637,-18.069,18.069,29.637
-9.8 -46.8 -29.637,-18.069,18.069,29.637
-9.8 -40 -29.637,-18.069,18.069,29.637
-9.8 -36.3 -29.637,-18.069,18.069,29.637
-9.8 -35.8 -29.637,-18.069,18.069,29.637
-9.8 -30 -29.637,-18.069,18.069,29.637
-9.8 -26.3 -29.637,-18.069,18.069,29.637
-9.8 -25.8 -29.637,-20.654,20.654,29.637
-9.8 -18.9 -29.637,-20.654,20.654,29.637
-9.8 -15.5 -29.637,-20.654,20.654,29.637
-9.8 -15.1 -29.637,-25.519,25.519,29.637
-9.8 -6.3 -29.637,-25.519,25.519,29.637
-9.8 0.1 -
-8 -58.3 -30.163,30.163
-8 -57.7 -30.163,-18.069,18.069,30.163
-8 -55.2 -30.163,-18.069,18.069,30.163
-8 -54.8 -30.163,-18.069,18.069,30.163
-8 -51.5 -30.163,-18.069,18.069,30.163
-8 -50 -30.163,-18.069,18.069,30.163
-8 -49 -30.163,-18.069,18.069,30.163
-8 -48.3 -30.163,-18.069,18.069,30.163
-8 -46.8 -30.163,-18.069,18.069,30.163
-8 -40 -30.163,-18.069,18.069,30.163
-8 -36.3 -30.163,-18.069,18.069,30.163
-8 -35.8 -30.163,-18.069,18.069,30.163
-8 -30 -30.163,-18.069,18.069,30.163
-8 -26.3 -30.163,-18.069,18.069,30.163
-8 -25.8 -30.163,-18.854,18.854,30.163
-8 -18.9 -30.163,-18.854,18.854,30.163
-8 -15.5 -30.163,-18.854,18.854,30.163
-8 -15.1 -30.163,-25.519,25.519,30.163
-8 -6.3 -30.163,-25.519,25.519,30.163
-8 0.1 -29.946,-25.519,25.519,29.946
-7.4 -58.3 -30.163,30.163
-7.4 -57.7 -30.163,-18.069,18.069,30.163
-7.4 -55.2 -30.163,-18.069,18.069,30.163
-7.4 -54.8 -30.163,-18.069,18.069,30.163
-7.4 -51.5 -30.163,-18.069,18.069,30.163
-7.4 -50 -30.163,-18.069,18.069,30.163
-7.4 -49 -30.163,-18.069,18.069,30.163
-7.4 -48.3 -30.163,-18.069,18.069,30.163
-7.4 -46.8 -30.163,-18.069,18.069,30.163
-7.4 -40 -30.163,-18.069,18.069,30.163
-7.4 -36.3 -30.163,-18.069,18.069,30.163
-7.4 -35.8 -30.163,-18.069,18.069,30.163
-7.4 -30 -30.163,-18.069,18.069,30.163
-7.4 -26.3 -30.163,-18.069,18.069,30.163
-7.4 -25.8 -30.163,-18.254,18.254,30.163
-7.4 -18.9 -30.163,-18.254,18.254,30.163
-7.4 -15.5 -30.163,-18.254,18.254,30.163
-7.4 -15.1 -30.163,-25.519,25.519,30.163
-7.4 -6.3 -30.163,-25.519,25.519,30.163
-7.4 0.1 -30.155,-25.519,25.519,30.155
-7 -58.3 -30.163,30.163
-7 -57.7 -30.163,-18.069,18.069,30.163
-7 -55.2 -30.163,-18.069,18.069,30.163
-7 -54.8 -30.163,-18.069,18.069,30.163
-7 -51.5 -30.163,-18.069,18.069,30.163
-7 -50 -30.163,-18.069,18.069,30.163
-7 -49 -30.163,-18.069,18.069,30.163
-7 -48.3 -30.163,-18.069,18.069,30.163
-7 -46.8 -30.163,-18.069,18.069,30.163
-7 -40 -30.163,-18.069,18.069,30.163
-7 -36.3 -30.163,-18.069,18.069,30.163
-7 -35.8 -30.163,-18.069,18.069,30.163
-7 -30 -30.163,-18.069,18.069,30.163
-7 -26.3 -30.163,-18.069,18.069,30.163
-7 -25.8 -30.163,-18.069,18.069,30.163
-7 -18.9 -30.163,-18.069,18.069,30.163
-7 -15.5 -30.163,-18.069,18.069,30.163
-7 -15.1 -30.163,-25.519,25.519,30.163
-7 -6.3 -30.163,-25.519,25.519,30.163
-7 0.1 -30.163,-25.519,25.519,30.163
-6.6 -58.3 -30.163,30.163
-6.6 -57.7 -30.163,-18.069,18.069,30.163
-6.6 -55.2 -30.163,-18.069,18.069,30.163
-6.6 -54.8 -30.163,-18.069,18.069,30.163
-6.6 -51.5 -30.163,-18.069,18.069,30.163
-6.6 -50 -30.163,-18.069,18.069,30.163
-6.6 -49 -30.163,-18.069,18.069,30.163
-6.6 -48.3 -30.163,-18.069,18.069,30.163
-6.6 -46.8 -30.163,-18.069,18.069,30.163
-6.6 -40 -30.163,-18.069,18.069,30.163
-6.6 -36.3 -30.163,-18.069,18.069,30.163
-6.6 -35.8 -30.163,-18.069,18.069,30.163
-6.6 -30 -30.163,-18.069,18.069,30.163
-6.6 -26.3 -30.163,-18.069,18.069,30.163
-6.6 -25.8 -30.163,-18.069,18.069,30.163
-6.6 -18.9 -30.163,-18.069,18.069,30.163
-6.6 -15.5 -30.163,-18.069,18.069,30.163
-6.6 -15.1 -30.163,-25.519,25.519,30.163
-6.6 -6.3 -30.163,-25.519,25.519,30.163
-6.6 0.1 -30.163,-25.519,25.519,30.163
-6.2 -58.3 -30.163,30.163
-6.2 -57.7 -30.163,-18.069,18.069,30.163
-6.2 -55.2 -30.163,-18.069,18.069,30.163
-6.2 -54.8 -30.163,-18.069,18.069,30.163
-6.2 -51.5 -30.163,-18.069,18.069,30.163
-6.2 -50 -30.163,-18.069,18.069,30.163
-6.2 -49 -30.163,-18.069,18.069,30.163
-6.2 -48.3 -30.163,-18.069,18.069,30.163
-6.2 -46.8 -30.163,-18.069,18.069,30.163
-6.2 -40 -30.163,-18.069,18.069,30.163
-6.2 -36.3 -30.163,-18.069,18.069,30.163
-6.2 -35.8 -30.163,-18.069,18.069,30.163
-6.2 -30 -30.163,-18.069,18.069,30.163
-6.2 -26.3 -30.163,-18.069,18.069,30.163
-6.2 -25.8 -30.163,-18.069,18.069,30.163
-6.2 -18.9 -30.163,-18.069,18.069,30.163
-6.2 -15.5 -30.163,-25.519,25.519,30.163
-6.2 -15.1 -30.163,-25.519,25.519,30.163
-6.2 -6.3 -30.163,-25.519,25.519,30.163
-6.2 0.1 -30.163,-25.519,25.519,30.163
-5.5 -58.3 -30.163,30.163
-5.5 -57.7 -30.163,-18.069,18.069,30.163
-5.5 -55.2 -30.163,-18.069,18.069,30.163
-5.5 -54.8 -30.163,-18.069,18.069,30.163
-5.5 -51.5 -30.163,-18.069,18.069,30.163
-5.5 -50 -30.163,-18.069,18.069,30.163
-5.5 -49 -30.163,-18.069,18.069,30.163
-5.5 -48.3 -30.163,-18.069,18.069,30.163
-5.5 -46.8 -30.163,-18.069,18.069,30.163
-5.5 -40 -30.163,-18.069,18.069,30.163
-5.5 -36.3 -30.163,-18.069,18.069,30.163
-5.5 -35.8 -30.163,-18.069,18.069,30.163
-5.5 -30 -30.163,-18.069,18.069,30.163
-5.5 -26.3 -30.163,-18.069,18.069,30.163
-5.5 -25.8 -30.163,-18.069,18.069,30.163
-5.5 -18.9 -30.163,-18.069,18.069,30.163
-5.5 -15.5 -30.163,-25.519,25.519,30.163
-5.5 -15.1 -30.163,-25.519,25.519,30.163
-5.5 -6.3 -30.163,-25.519,25.519,30.163
-5.5 0.1 -30.163,-25.519,25.519,30.163
-5.2 -58.3 -30.163,30.163
-5.2 -57.7 -30.163,-18.069,18.069,30.163
-5.2 -55.2 -30.163,-18.069,18.069,30.163
-5.2 -54.8 -30.163,-18.069,18.069,30.163
-5.2 -51.5 -30.163,-18.069,18.069,30.163
-5.2 -50 -30.163,-18.069,18.069,30.163
-5.2 -49 -30.163,-18.069,18.069,30.163
-5.2 -48.3 -30.163,-18.069,18.069,30.163
-5.2 -46.8 -30.163,-18.069,18.069,30.163
-5.2 -40 -30.163,-18.069,18.069,30.163
-5.2 -36.3 -30.163,-18.069,18.069,30.163
-5.2 -35.8 -30.163,-18.069,18.069,30.163
-5.2 -30 -30.163,-18.069,18.069,30.163
-5.2 -26.3 -30.163,-18.069,18.069,30.163
-5.2 -25.8 -30.163,-18.069,18.069,30.163
-5.2 -18.9 -30.163,-18.069,18.069,30.163
-5.2 -15.5 -30.163,-25.519,25.519,30.163
-5.2 -15.1 -30.163,-25.519,25.519,30.163
-5.2 -6.3 -30.163,-25.519,25.519,30.163
-5.2 0.1 -30.163,-25.519,25.519,30.163
-4.95 -58.3 -30.163,30.163
-4.95 -57.7 -30.163,-18.069,18.069,30.163
-4.95 -55.2 -30.163,-18.069,18.069,30.163
-4.95 -54.8 -30.163,-18.069,18.069,30.163
-4.95 -51.5 -30.163,-18.069,18.069,30.163
-4.95 -50 -30.163,-19.376,19.376,30.163
-4.95 -49 -30.163,-20.376,20.376,30.163
-4.95 -48.3 -30.163,-21.076,21.076,30.163
-4.95 -46.8 -30.163,-22.331,22.331,30.163
-4.95 -40 -30.163,-22.331,22.331,30.163
-4.95 -36.3 -30.163,-22.331,22.331,30.163
-4.95 -35.8 -30.163,-25.519,25.519,30.163
-4.95 -30 -30.163,-25.519,25.519,30.163
-4.95 -26.3 -30.163,-25.519,25.519,30.163
-4.95 -25.8 -30.163,-25.519,25.519,30.163
-4.95 -18.9 -30.163,-25.519,25.519,30.163
-4.95 -15.5 -30.163,-25.519,25.519,30.163
-4.95 -15.1 -30.163,-25.519,25.519,30.163
-4.95 -6.3 -30.163,-25.519,25.519,30.163
-4.95 0.1 -30.163,-25.519,25.519,30.163
-3 -58.3 -30.163,30.163
-3 -57.7 -30.163,-18.069,18.069,30.163
-3 -55.2 -30.163,-18.069,18.069,30.163
-3 -54.8 -30.163,-18.069,18.069,30.163
-3 -51.5 -30.163,-18.069,18.069,30.163
-3 -50 -30.163,-19.376,19.376,30.163
-3 -49 -30.163,-20.376,20.376,30.163
-3 -48.3 -30.163,-21.076,21.076,30.163
-3 -46.8 -30.163,-22.331,22.331,30.163
-3 -40 -30.163,-22.331,22.331,30.163
-3 -36.3 -30.163,-22.331,22.331,30.163
-3 -35.8 -30.163,-25.519,25.519,30.163
-3 -30 -30.163,-25.519,25.519,30.163
-3 -26.3 -30.163,-25.519,25.519,30.163
-3 -25.8 -30.163,-25.519,25.519,30.163
-3 -18.9 -30.163,-25.519,25.519,30.163
-3 -15.5 -30.163,-25.519,25.519,30.163
-3 -15.1 -30.163,-25.519,25.519,30.163
-3 -6.3 -30.163,-25.519,25.519,30.163
-3 0.1 -30.163,-25.519,25.519,30.163
-1 -58.3 -30.163,30.163
-1 -57.7 -30.163,-18.069,18.069,30.163
-1 -55.2 -30.163,-18.069,18.069,30.163
-1 -54.8 -30.163,-18.069,18.069,30.163
-1 -51.5 -30.163,-18.069,18.069,30.163
-1 -50 -30.163,-19.376,19.376,30.163
-1 -49 -30.163,-20.376,20.376,30.163
-1 -48.3 -30.163,-21.076,21.076,30.163
-1 -46.8 -30.163,-22.331,22.331,30.163
-1 -40 -30.163,-22.331,22.331,30.163
-1 -36.3 -30.163,-22.331,22.331,30.163
-1 -35.8 -30.163,-25.519,25.519,30.163
-1 -30 -30.163,-25.519,25.519,30.163
-1 -26.3 -30.163,-25.519,25.519,30.163
-1 -25.8 -30.163,-25.519,25.519,30.163
-1 -18.9 -30.163,-25.519,25.519,30.163
-1 -15.5 -30.163,-25.519,25.519,30.163
-1 -15.1 -30.163,-25.519,25.519,30.163
-1 -6.3 -30.163,-25.519,25.519,30.163
-1 0.1 -30.163,-25.519,25.519,30.163
0.3 -58.3 -30.163,30.163
0.3 -57.7 -30.163,-18.069,18.069,30.163
0.3 -55.2 -30.163,-18.069,18.069,30.163
0.3 -54.8 -30.163,-18.069,18.069,30.163
0.3 -51.5 -30.163,-18.069,18.069,30.163
0.3 -50 -30.163,-19.376,19.376,30.163
0.3 -49 -30.163,-20.376,20.376,30.163
0.3 -48.3 -30.163,-21.076,21.076,30.163
0.3 -46.8 -30.163,-22.331,22.331,30.163
0.3 -40 -30.163,-22.331,22.331,30.163
0.3 -36.3 -30.163,-22.331,22.331,30.163
0.3 -35.8 -30.163,-25.519,25.519,30.163
0.3 -30 -30.163,-25.519,25.519,30.163
0.3 -26.3 -30.163,-25.519,25.519,30.163
0.3 -25.8 -30.163,-25.519,25.519,30.163
0.3 -18.9 -30.163,-25.519,25.519,30.163
0.3 -15.5 -30.163,-25.519,25.519,30.163
0.3 -15.1 -30.163,-25.519,25.519,30.163
0.3 -6.3 -30.163,-25.519,25.519,30.163
0.3 0.1 -30.163,-25.519,25.519,30.163
0.7 -58.3 -30.163,30.163
0.7 -57.7 -30.163,30.163
0.7 -55.2 -30.163,30.163
0.7 -54.8 -30.163,-11.973,-11.023,11.023,11.973,30.163
0.7 -51.5 -30.163,-11.973,-11.023,11.023,11.973,30.163
0.7 -50 -30.163,-11.973,-11.023,11.023,11.973,30.163
0.7 -49 -30.163,-11.973,-11.023,11.023,11.973,30.163
0.7 -48.3 -30.163,30.163
0.7 -46.8 -30.163,30.163
0.7 -40 -30.163,30.163
0.7 -36.3 -30.163,30.163
0.7 -35.8 -30.163,30.163
0.7 -30 -30.163,30.163
0.7 -26.3 -30.163,30.163
0.7 -25.8 -30.163,30.163
0.7 -18.9 -30.163,30.163
0.7 -15.5 -30.163,30.163
0.7 -15.1 -30.163,30.163
0.7 -6.3 -30.163,-11.845,11.845,30.163
0.7 0.1 -30.163,-11.845,11.845,30.163
1.35 -58.3 -30.163,30.163
1.35 -57.7 -30.163,30.163
1.35 -55.2 -30.163,30.163
1.35 -54.8 -30.163,-11.973,-11.023,11.023,11.973,30.163
1.35 -51.5 -30.163,-11.973,-11.023,11.023,11.973,30.163
1.35 -50 -30.163,-11.973,-11.023,11.023,11.973,30.163
1.35 -49 -30.163,-11.973,-11.023,11.023,11.973,30.163
1.35 -48.3 -30.163,30.163
1.35 -46.8 -30.163,30.163
1.35 -40 -30.163,30.163
1.35 -36.3 -30.163,30.163
1.35 -35.8 -30.163,30.163
1.35 -30 -30.163,30.163
1.35 -26.3 -30.163,30.163
1.35 -25.8 -30.163,30.163
1.35 -18.9 -30.163,30.163
1.35 -15.5 -30.163,30.163
1.35 -15.1 -30.163,30.163
1.35 -6.3 -30.163,-11.845,11.845,30.163
1.35 0.1 -30.163,-11.845,11.845,30.163
2 -58.3 -30.163,30.163
2 -57.7 -30.163,30.163
2 -55.2 -30.163,-12.119,-9.848,9.848,12.119,30.163
2 -54.8 -30.163,-12.631,-9.848,9.848,12.631,30.163
2 -51.5 -30.163,-13.963,-9.848,9.848,13.963,30.163
2 -50 -30.163,-13.576,-9.848,9.848,13.576,30.163
2 -49 -30.163,-12.909,-9.848,9.848,12.909,30.163
2 -48.3 -30.163,-12.086,-9.848,9.848,12.086,30.163
2 -46.8 -30.163,30.163
2 -40 -30.163,30.163
2 -36.3 -30.163,30.163
2 -35.8 -30.163,30.163
2 -30 -30.163,30.163
2 -26.3 -30.163,30.163
2 -25.8 -30.163,30.163
2 -18.9 -30.163,30.163
2 -15.5 -30.163,30.163
2 -15.1 -30.163,30.163
2 -6.3 -30.163,30.163
2 0.1 -30.163,-11.845,11.845,30.163
5.2 -58.3 -30.163,30.163
5.2 -57.7 -30.163,30.163
5.2 -55.2 -30.163,-12.122,-7.574,7.574,12.122,30.163
5.2 -54.8 -30.163,-12.634,-7.063,7.063,12.634,30.163
5.2 -51.5 -30.163,-13.962,-5.734,5.734,13.962,30.163
5.2 -50 -30.163,-13.576,-6.12,6.12,13.576,30.163
5.2 -49 -30.163,-12.912,-6.785,6.785,12.912,30.163
5.2 -48.3 -30.163,-12.091,-7.607,7.607,12.091,30.163
5.2 -46.8 -30.163,30.163
5.2 -40 -30.163,30.163
5.2 -36.3 -30.163,30.163
5.2 -35.8 -30.163,30.163
5.2 -30 -30.163,30.163
5.2 -26.3 -30.163,30.163
5.2 -25.8 -30.163,30.163
5.2 -18.9 -30.163,30.163
5.2 -15.5 -30.163,30.163
5.2 -15.1 -30.163,30.163
5.2 -6.3 -30.163,30.163
5.2 0.1 -30.163,30.163
# end dock_fixture.txt
```

### Step 3 — geometry checks

Build measurement-frame geometry with the added features off, then compare.

```bash
export OPENSCADPATH=~/Documents/OpenSCAD/libraries
OSC=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
LIB=~/Documents/OpenSCAD/libraries/hosl/'dewalt 20v.scad'

# NOTE the bare `echo` first: the .scad may not end in a newline, and without it
# the appended call lands on the trailing comment line and is silently ignored
# ("Current top level object is empty").
{ cat "$LIB"; echo
  echo 'rotate([-90,0,0]) dewalt_20v_negative(anchor="step");'; } > /tmp/t.scad
$OSC -o /tmp/neg_pure.stl -D 'entry_chamfer=0' -D 'terminal_bore=false' /tmp/t.scad
```

Extract with `sed -n '/^# fixcheck.py$/,/^# end fixcheck.py$/p' 'dewalt 20v.md' > fixcheck.py`
and run `python3 fixcheck.py /tmp/neg_pure.stl`.

```python
# fixcheck.py
import sys
from meshprobe import Solid

def load_fixture(path='dock_fixture.txt'):
    out=[]
    for ln in open(path):
        ln=ln.strip()
        if not ln or ln.startswith('#'): continue
        y,z,rest = ln.split()
        v=[] if rest=='-' else [float(t) for t in rest.split(',')]
        out.append((float(y), float(z), [(v[i],v[i+1]) for i in range(0,len(v),2)]))
    return out

def ivs(s,y,z):
    xs=s.xs(y,z); return [(xs[i],xs[i+1]) for i in range(0,len(xs)-1,2)]

def uncovered(gap,cov):
    a0,a1=gap; u=a1-a0
    for c0,c1 in cov: u-=max(0,min(a1,c1)-max(a0,c0))
    return u

neg=Solid([sys.argv[1] if len(sys.argv)>1 else '/tmp/neg_pure.stl'])
inter=miss=0; wi=wm=0.0
for y,z,D in load_fixture():
    N=ivs(neg,y,z)
    for a in N:
        for b in D:
            o=min(a[1],b[1])-max(a[0],b[0])
            if o>1e-3: inter+=1; wi=max(wi,o)
    if y<=0.45:
        for i in range(len(D)-1):
            u=uncovered((D[i][1],D[i+1][0]),N)
            if u>1e-3: miss+=1; wm=max(wm,u)
ok = inter==0 and miss==0
print(f'fixture: interference {inter} ({wi:.3f} mm) | uncovered {miss} ({wm:.3f} mm)  -> {"PASS" if ok else "FAIL"}')
sys.exit(0 if ok else 1)
# end fixcheck.py
```

### Step 4 — anchor placement check

Needs no dock data at all. Catches the `_zup()` drift the geometry checks are
blind to. Extract with
`sed -n '/^# anchorcheck.py$/,/^# end anchorcheck.py$/p' 'dewalt 20v.md' > anchorcheck.py`.

```python
# anchorcheck.py
import subprocess, sys, os
from meshprobe import Solid
LIB = sys.argv[1] if len(sys.argv)>1 else os.path.expanduser('~/github/hosl/dewalt 20v.scad')
OSC = '/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD'
# Expected EMITTED (Z-up) position of each anchor. Hard-coded on purpose:
# deriving these via _zup() would be circular and blind to the very drift this
# test exists to catch.
EXPECT = {
 'step':       (0.0,    0.0,     0.0),
 'mouth':      (0.0,  -12.170, -9.922),
 'backstop':   (0.0,   58.010, -9.922),
 'deck':       (0.0,   51.760,  0.500),
 'latch-face': (0.0,   -0.250,  0.500),
 'terminal-l': (-11.498, 51.760, 1.500),
 'terminal-r': ( 11.498, 51.760, 1.500),
}
def bbox_for(anchor):
    src = open(LIB).read() + '\n' + f'dewalt_20v_negative(anchor="{anchor}");\n'
    open('/tmp/_a.scad','w').write(src)
    subprocess.run([OSC,'-o','/tmp/_a.stl','/tmp/_a.scad'],capture_output=True,
                   env={**os.environ,'OPENSCADPATH':os.path.expanduser('~/Documents/OpenSCAD/libraries')})
    return Solid(['/tmp/_a.stl']).bbox()
base = bbox_for('step'); ok=True
for a,(ex,ey,ez) in EXPECT.items():
    b = bbox_for(a)
    shift = tuple(b[i][0]-base[i][0] for i in range(3))
    want  = (-ex,-ey,-ez)
    good  = all(abs(shift[i]-want[i])<2e-3 for i in range(3)); ok &= good
    print(f'   {a:12s} shift={tuple(round(v,3) for v in shift)!s:26s} want={want!s:26s} {"OK" if good else "BAD"}')
print('anchors PASS' if ok else 'anchors FAIL')
sys.exit(0 if ok else 1)
# end anchorcheck.py
```

### Expected output

```
fixture: interference 0 (0.000 mm) | uncovered 0 (0.000 mm)  -> PASS
   step         ... OK      mouth      ... OK      backstop   ... OK
   deck         ... OK      latch-face ... OK      terminal-l ... OK
   terminal-r   ... OK
anchors PASS
```


### Gotchas that cost time

- **`--render` takes an argument**: `--render=cgal`. Bare `--render` swallows the
  filename and dumps the help text.
- **`-D` cannot set module parameters.** `-D anchor='"mouth"'` does nothing,
  because `anchor` is a parameter with a literal default, not a global. To test
  anchors, `sed` the demo call. (`-D entry_chamfer=0` *does* work — that one is
  a genuine global.)
- **`use <>` does not import top-level variables**, only modules and functions.
  Including this library with `use` yields an empty render because every TUNE
  value comes through as `undef`. Use `include <>`. `preview_overlay.scad`
  relies on this.
- Previews need `--autocenter --viewall`, otherwise the camera sits inside the
  model.
- **`preview_overlay.scad` rotates the dock imports, not the negative.** The
  module emits Z-up; the STLs are measurement-frame. If the overlay ever looks
  90° apart, that `rot([90,0,0])` on the imports is the first suspect.
- **Rendering `dewalt_20v_negative.scad` directly produces nothing** — it has no
  top-level geometry by design (§8). Render `demo.scad` or `preview_overlay.scad`
  instead, or append a call the way §6 does. OpenSCAD's only complaint is
  `Current top level object is empty`, which is easy to misread as a broken model.
- Preview renders no longer need a `sed` to inject a rotation — the module is
  Z-up natively. Old scripts that added `rotate([90,0,0])` will now double-rotate.

---

## 7. Confidence, and what to check against a real pack

The measurements are exact **with respect to the STEP file**. The open question
is whether that third-party dock is itself faithful to a genuine pack — nothing
here was validated against physical hardware.

Caliper-check in this order:

1. **Latch geometry** — retention face at Z +0.250 and the 1.050 cam ramp.
   Most likely to have been simplified by the original modeller, and the thing
   that makes the pack actually stay in.
2. **Rail undercut** — `rail_floor_y` −5.072 and `rail_half_x` 25.519. Governs
   whether the pack takes load or rocks.
3. **Terminal slot X ±11.498** — cross-check against a pack; get this wrong and
   the spades miss.

Lower priority: the mouth reliefs (§4). They only open the entrance and sit
outside the seated pack, so error there costs nothing functionally.

`clearance` defaults to **0** deliberately: the source is a *dock*, so it already
carries DeWalt's running clearance. Adding 0.2–0.3 on top stacks two allowances
and goes sloppy. Raise it only for printer tolerance.

Electrical, unrelated to geometry: many genuine tools refuse to run unless the
middle pins are faked — 10k B+→TH, 2k B+→C3, 3k B−→C3. This dock breaks out
only B+/B−, so a tool-side adapter will likely need those resistors added.

---

## 8. Where it lives

Already installed:

```
~/github/hosl/dewalt 20v.scad
~/Documents/OpenSCAD/libraries/hosl  ->  ~/github/hosl     (symlink)
```

`hosl` is a **git repo** — which is now the only backup this work has, so commit
changes. It also holds `openscad-library-conversion.md`, a house guide to the
library pattern used by the other files there (`$`-prefixed setup module, `_`
internal modules, `use` instead of `include`). **This library does not follow
that pattern** — it uses top-level globals, which is why it needs `include`.
Converting it is optional future work, not a defect.

```openscad
include <hosl/dewalt 20v.scad>     // the space in the filename is fine
```

Nothing else is needed at render time — just this file and BOSL2.

### `include`, never `use`

`use <>` imports modules and functions but **not top-level variables**. The
entire TUNE block would arrive as `undef` and the module would render nothing —
silently, with no error. Always `include <>`.

### Why the library has no top-level geometry

`include` *executes* the file. Any top-level geometry in the library is injected
into every model that includes it — a phantom solid at the origin that you will
waste an afternoon on. This was demonstrated, not theorised: a file whose only
content was `include <hosl/dewalt 20v.scad>; cube([1,1,1]);` came out with a
bounding box of 60 × 80 × 20 mm.

So the library ends at the last `module`/`function`. **If you add a quick test
block to the bottom while working, delete it before committing.**

A consequence: opening `dewalt 20v.scad` in the GUI renders nothing. That is
correct for a library, but reads as a broken model. Use the demo in §9.

### Keep a trailing newline

The file must end with a newline. Without one, anything appended to it (as §6
does) lands on the final comment line and is silently swallowed — OpenSCAD just
says `Current top level object is empty`. This bit the documented verification
pipeline once already.

### BOSL2

The library `include`s `BOSL2/std.scad`, so BOSL2 must be in the same library
folder (it is: `~/Documents/OpenSCAD/libraries/BOSL2`). If you move this to
another machine, BOSL2 has to come too — `attachable()`, `named_anchor()`,
`prismoid()`, `cuboid()` and `rot()` are all load-bearing.

---

## 9. Working files (reproduced — the originals were deleted)

### Demo body

Paste into a new file to see the pocket cut into something. This is also the
quickest smoke test that the library still works.

```openscad
include <hosl/dewalt 20v.scad>

difference() {
    cube([60, 80, 20], anchor = FRONT + BOTTOM);
    dewalt_20v_negative(anchor = "mouth");
}
```

At 60 mm wide that leaves 4.48 mm of side wall along the pocket, narrowing to
3.28 mm at the mouth where the entry flare is widest. Renders `Genus: 2` — the
two spade bores exiting the top face. Both confirmed fully patent.

### Overlay fit check — needs the dock STLs, so it cannot run today

Kept for the day the STLs come back. The negative should exactly fill the dock's
pocket; the only permitted breakouts are the two added features (spade bores up
through the terminal towers, entry flare in front of the dock's front face).

```openscad
// include, not use: `use` would not import the library's TUNE variables.
include <hosl/dewalt 20v.scad>
dewalt_20v_negative();

// The module emits Z-up but the dock STLs are measurement-frame (Y-up), so the
// imports need the same rot([90,0,0]) the module applies internally. If the two
// ever look 90 deg apart, this line is the first suspect.
rot([90, 0, 0])
    color("#93a9bd", 0.28) {
        import("battery_dock_lower.stl");
        import("battery_dock_upper.stl");
    }
```

`import()` resolves relative to the file containing the call, so that file has to
sit beside the STLs — not in the library folder.

### Rendering previews

The library emits nothing on its own (§8), so append a call first:

```bash
export OPENSCADPATH=~/Documents/OpenSCAD/libraries
OSC=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
{ cat ~/Documents/OpenSCAD/libraries/hosl/'dewalt 20v.scad'; echo
  echo 'dewalt_20v_negative();'; } > /tmp/pv.scad
$OSC -o iso.png --imgsize=1200,900 --camera=0,0,0,62,0,35,140 \
     --autocenter --viewall --render=cgal --colorscheme=Tomorrow /tmp/pv.scad
```

Useful camera rotations: `62,0,35` iso-front, `62,0,215` iso-rear,
`118,0,35` underside, `90,0,0` end-on.
