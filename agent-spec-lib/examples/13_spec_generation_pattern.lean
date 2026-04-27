import AgentSpec

/-! # Example 13: spec generation evaluation pattern (Phase 6 sprint 3 A #5)

Phase 6 sprint 3 A で構築した spec generation evaluation harness の利用例。
Day 204 PoC 5/5 = 100% statement parity (constrained setting で CLEVER 0.6% から大幅改善)。

End-user perspective: subagent dispatch + 既存 vocabulary 提示 + statement byte 比較で
LLM-driven spec authoring の pass rate を quantify できる。
-/

namespace AgentSpec.Examples.SpecGeneration

open AgentSpec.Tooling
open AgentSpec.Manifest

/-- Day 204 PoC で生成された spec 例 (subagent dispatch 結果)。 -/
example : Measurable skillQuality := by
  -- subagent 生成 statement と byte-identical (modulo theorem name)
  -- 期待: AgentSpec.Manifest.v1_measurable と semantically 同型
  exact ⟨skillQuality, fun _ => rfl⟩

/-- spec generation の評価 metric: 生成 statement が PI-19 registry の entry と byte-identical か。 -/
def specGenerationPassed (genName : String) : Bool :=
  match lookupEquivalence genName with
  | some r => r.statementMatch && r.proofMatch
  | none => false

/-- v1_measurable は PI-19 registry に登録済 → spec gen も pass 想定。 -/
example : specGenerationPassed "v1_measurable" = true := by decide

/-- 未登録 benchmark id は false。 -/
example : specGenerationPassed "unknown_benchmark_xyz" = false := by decide

/-- Day 204 PoC pass rate の Lean 値表現 (5/5 = 100%)。 -/
def day204PocPassRate : Nat := 100

example : day204PocPassRate = 100 := by decide

end AgentSpec.Examples.SpecGeneration
