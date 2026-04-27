import AgentSpec

/-! # Example 03: OpaqueOrigin registry — semantic origin lookup

Day 160 PI-13 で導入した opaque def semantic origin registry の利用例。
V1-V7 + 主要 metric の measurement origin を Lean 値として参照可能。

End-user perspective: Manifest の opaque def (skillQuality 等) が
「どの benchmark / どの measure」 由来か、docstring 検索ではなく
typed list で query できる。
-/

namespace AgentSpec.Examples.OpaqueOrigin

open AgentSpec.Tooling

/-- registry サイズ (Day 160 initial: 10 entry)。 -/
example : opaqueOriginRegistry.length = 10 := by decide

/-- skillQuality (V1) の origin 文字列を検索する関数の例。 -/
def lookupOrigin (name : String) : Option String :=
  (opaqueOriginRegistry.find? (fun e => e.1 == name)).map (·.2.1)

/-- skillQuality は benchmark.json GQM Q1 由来。 -/
example : lookupOrigin "skillQuality" = some "benchmark.json GQM Q1 (with/without comparison)" := by
  decide

/-- 未登録 opaque def は none。
    残 22 件 (canTransition, generates 等) は incremental 追加候補 (PI-13 follow-up)。 -/
example : lookupOrigin "canTransition" = none := by decide

end AgentSpec.Examples.OpaqueOrigin
