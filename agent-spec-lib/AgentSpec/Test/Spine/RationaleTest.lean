import AgentSpec.Spine.Rationale

/-!
# AgentSpec.Test.Spine.RationaleTest: Rationale structure の behavior test

Day 44 hole-driven minimal: structure 3 field + 4 smart constructor + isTrivial の検証。
GA-S8 (judgmental 構造化) の Lean 着手、各 type attach は Day 45+。
-/

namespace AgentSpec.Test.Spine.Rationale

open AgentSpec.Spine

/-! ### structure 構築 -/

/-- 全 field 直接指定 -/
example : Rationale := { text := "hypothesis confirmed", references := ["DOI:10.1145/x"], confidence := 85 }

/-- 最小構築 (trivial と等価) -/
example : Rationale := { text := "", references := [], confidence := 0 }

/-! ### field projection -/

example :
    ({text := "t", references := [], confidence := 42} : Rationale).text = "t" := rfl
example :
    ({text := "", references := ["a", "b"], confidence := 0} : Rationale).references = ["a", "b"] := rfl
example :
    ({text := "", references := [], confidence := 99} : Rationale).confidence = 99 := rfl

/-! ### Smart constructor ofText / mk' / addReference -/

example : Rationale.ofText "evidence by induction" 80 =
          { text := "evidence by induction", references := [], confidence := 80 } := rfl

example : Rationale.mk' "h" ["r1", "r2"] 50 =
          { text := "h", references := ["r1", "r2"], confidence := 50 } := rfl

example :
    (Rationale.ofText "t" 10).addReference "new-ref" =
    { text := "t", references := ["new-ref"], confidence := 10 } := rfl

example :
    (Rationale.mk' "h" ["r1"] 50).addReference "r2" =
    { text := "h", references := ["r1", "r2"], confidence := 50 } := rfl

/-! ### trivial fixture + isTrivial -/

example : Rationale.trivial = { text := "", references := [], confidence := 0 } := rfl

example : Rationale.trivial.isTrivial = true := rfl

example : (Rationale.ofText "x" 0).isTrivial = false := rfl
example : (Rationale.mk' "" ["r"] 0).isTrivial = false := rfl
example : (Rationale.mk' "" [] 1).isTrivial = false := rfl

/-! ### DecidableEq / Inhabited -/

example : DecidableEq Rationale := inferInstance
example : Inhabited Rationale := inferInstance

/-- 同値判定 -/
example :
    (Rationale.ofText "same" 50) = (Rationale.ofText "same" 50) := by decide

/-- 異値判定 (text 違い) -/
example :
    (Rationale.ofText "a" 50) ≠ (Rationale.ofText "b" 50) := by decide

/-- 異値判定 (confidence 違い) -/
example :
    (Rationale.ofText "x" 10) ≠ (Rationale.ofText "x" 20) := by decide

/-- 異値判定 (references 違い) -/
example :
    (Rationale.mk' "x" ["a"] 10) ≠ (Rationale.mk' "x" ["b"] 10) := by decide

end AgentSpec.Test.Spine.Rationale
