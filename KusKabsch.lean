/-
  Rank-1 Kabsch completion (ik_kabsch_6d.cpp, svd3): when the cross-covariance has rank 1 only the
  swing axis is pinned (u0 <- v0); the perpendicular (twist) plane is free. Any perpendicular is a
  legal completion, so we pick the CANONICAL one -- minimal twist -- by carrying V's free axes
  v1,v2 through the shortest arc R0 : v0 -> u0. Then U = [u0, R0 v1, R0 v2], V = [v0,v1,v2], and
  R = U V^T = R0, the swing-only rotation.

  The construction and its checks now live in contract-rotation-star, the home of the rotational
  star solver: frameOf, rod, canonCompletion and anyCompletion in RotationStar.Completion, and the
  cases (TCase), canonOK and anyHasMinimalTwist in RotationStar.Props, with the same generators
  and tolerances as this file had. This file runs the same two Plausible checks on them:
    1. [u0,c1,c2] is orthonormal and right-handed  => R is a proper rotation,
    2. R v0 = u0                                    => the pinned correspondence is preserved,
    3. axis(R) . u0 = 0                             => MINIMAL TWIST (shortest arc),
  and the contrast with get_any_perpendicular()-style completion, which leaves a nonzero twist
  (axis(R) . u0 != 0) -- the discontinuity-prone behavior the canonicalization removes.

    lake env lean KusKabsch.lean
-/
import RotationStar.Props

open RotationStar.Props

#eval "=== canonical completion: proper rotation, maps v0->u0, MINIMAL TWIST (expect no counterexample) ==="
#eval Plausible.Testable.check (cfg := { numInst := 4000 }) (∀ t : TCase, canonOK t = true)
#eval "=== arbitrary (any-perp) completion claims minimal twist -- expect COUNTEREXAMPLES (it has twist) ==="
#eval Plausible.Testable.check (cfg := { numInst := 4000 }) (∀ t : TCase, anyHasMinimalTwist t = true)
