/-
  Kusudama swept-cone nearest-projection spec, for the two-cone pair.

  A joint constraint is composed from separate two-cone kusudama modifiers, so
  the pair is the unit modelled here: one cone swept to the next along the
  great-circle path, radius interpolated, giving a single connected corridor.
  A pair has no non-adjacent-cone gap, so its region stays connected and the
  disconnected-chain routing problem never arises.

  Mirrors scene/resources/3d/joint_limitation_kusudama_3d.cpp `_solve`: the snap
  is the nearest boundary over the two cones and their interpolated centres, and
  the same sweep decides membership, so a snap candidate always lies on an
  allowed cone by construction.

  The fixtures are decided by interval, not tolerance: a direction is outside
  when its region margin exceeds the sampling gap (the path angle over the step
  count), and the snap must land within that gap. `native_decide` pins the cases
  at build time, the same shape as CassieAvbd/PolarDecomp.lean.
-/

namespace Kusudama.SweptCone

structure V3 where
  x : Float
  y : Float
  z : Float
deriving Inhabited

def V3.dot (a b : V3) : Float := a.x * b.x + a.y * b.y + a.z * b.z
def V3.cross (a b : V3) : V3 := ⟨a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x⟩
def V3.len (a : V3) : Float := Float.sqrt (a.dot a)
def V3.scale (a : V3) (s : Float) : V3 := ⟨a.x * s, a.y * s, a.z * s⟩
def V3.add (a b : V3) : V3 := ⟨a.x + b.x, a.y + b.y, a.z + b.z⟩
def V3.sub (a b : V3) : V3 := ⟨a.x - b.x, a.y - b.y, a.z - b.z⟩
def V3.norm (a : V3) : V3 := let l := a.len; if l > 1e-12 then a.scale (1.0 / l) else a
def V3.angleTo (a b : V3) : Float := Float.atan2 (a.cross b).len (a.dot b)

def deg (d : Float) : Float := d * 3.14159265358979323846 / 180.0

def slerp (a b : V3) (t : Float) : V3 :=
  let a := a.norm
  let b := b.norm
  let om := a.angleTo b
  if om < 1e-6 then a
  else
    let s := Float.sin om
    (a.scale (Float.sin ((1.0 - t) * om) / s)).add (b.scale (Float.sin (t * om) / s)) |>.norm

structure Cone where
  c : V3
  r : Float

abbrev Chain := List Cone

def SWEEP_STEPS : Nat := 64

def coneBoundary (p : V3) (c : V3) (r : Float) : V3 :=
  let c := c.norm
  let proj := p.sub (c.scale (p.dot c))
  let proj := if proj.len < 1e-9 then (c.cross ⟨0, 1, 0⟩).norm else proj.norm
  ((c.scale (Float.cos r)).add (proj.scale (Float.sin r))).norm

def regionMargin (ch : Chain) (d : V3) : Float :=
  let d := d.norm
  let coneMin := ch.foldl (fun m cn => min m (d.angleTo cn.c.norm - cn.r)) 1e9
  let pairs := ch.zip (ch.drop 1)
  pairs.foldl (fun m (a, b) =>
    (List.range (SWEEP_STEPS + 1)).foldl (fun mm s =>
      let t := s.toFloat / SWEEP_STEPS.toFloat
      min mm (d.angleTo (slerp a.c b.c t) - (a.r + (b.r - a.r) * t))) m) coneMin

def snap (ch : Chain) (d : V3) : V3 :=
  let d := d.norm
  if regionMargin ch d ≤ 0.0 then d
  else
    let step := fun (best : Float × V3) (c : V3) (r : Float) =>
      let b := coneBoundary d c r
      let dist := d.angleTo b
      if dist < best.1 then (dist, b) else best
    let afterCones := ch.foldl (fun acc cn => step acc cn.c cn.r) ((1e9 : Float), d)
    let pairs := ch.zip (ch.drop 1)
    (pairs.foldl (fun acc (a, b) =>
      (List.range (SWEEP_STEPS + 1)).foldl (fun accu s =>
        let t := s.toFloat / SWEEP_STEPS.toFloat
        step accu (slerp a.c b.c t) (a.r + (b.r - a.r) * t)) acc) afterCones).2

def pathGap (ch : Chain) : Float :=
  let pairs := ch.zip (ch.drop 1)
  pairs.foldl (fun g (a, b) => max g (a.c.norm.angleTo b.c.norm / SWEEP_STEPS.toFloat)) 0.0

def inRegion (ch : Chain) (d : V3) : Bool := regionMargin ch d ≤ pathGap ch

-- Two-cone pairs: the composition unit. Equal-radius, wide-radius, and a narrow
-- corridor, each 90 degrees apart.
def pairEqual : Chain := [⟨⟨0, 1, 0⟩, deg 10⟩, ⟨⟨1, 0, 0⟩, deg 10⟩]
def pairWide : Chain := [⟨⟨0, 1, 0⟩, deg 30⟩, ⟨⟨1, 0, 0⟩, deg 20⟩]
def pairNarrow : Chain := [⟨⟨0, 1, 0⟩, deg 8⟩, ⟨⟨0, 0, 1⟩, deg 8⟩]

def outside : V3 := (V3.mk (-1) (-1) (-1)).norm

-- A direction that misses both cones but sits over the corridor between them.
def betweenPair : V3 := (V3.mk 1 1 0).norm

def controlOutsideIsOut : Bool := regionMargin pairEqual outside > pathGap pairEqual
def snapIsInRegion : Bool := inRegion pairEqual (snap pairEqual outside)
def inRegionUnchanged : Bool := (snap pairEqual ⟨0, 1, 0⟩).angleTo ⟨0, 1, 0⟩ < deg 0.01
def corridorHolds : Bool := inRegion pairEqual betweenPair
def snapInRegionWide : Bool := inRegion pairWide (snap pairWide outside)
def snapInRegionNarrow : Bool := inRegion pairNarrow (snap pairNarrow outside)

example : controlOutsideIsOut = true := by native_decide
example : snapIsInRegion = true := by native_decide
example : inRegionUnchanged = true := by native_decide
example : corridorHolds = true := by native_decide
example : snapInRegionWide = true := by native_decide
example : snapInRegionNarrow = true := by native_decide

end Kusudama.SweptCone
