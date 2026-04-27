import AgentSpec

/-! # Example 11: SemanticEquivalence registry — source-port equivalence query

Phase 5 PI-19 (Day 194) で導入した SemanticEquivalence registry の利用例。
26 critical theorems の source-port equivalence (statement parity + proof byte-identical)
を Lean 値レベルで query 可能。
-/

namespace AgentSpec.Examples.SemanticEquivalence

open AgentSpec.Tooling

/-- registry サイズ確認 (26 critical theorems、Phase 5 #3 acceptance)。 -/
example : equivalenceRegistry.length = 26 := by decide

/-- 全 entry で statement + proof 一致 = source-port semantic 同型。 -/
example : equivalenceRegistry.all (fun r => r.statementMatch && r.proofMatch) = true := by
  decide

/-- 特定 theorem の equivalence record lookup (例: d2_from_e1)。 -/
example : (lookupEquivalence "d2_from_e1").isSome = true := by decide

/-- d2_from_e1 の axiom dependency: verification_requires_independence (E1) 由来。 -/
example : ((lookupEquivalence "d2_from_e1").map (·.axiomDeps)) =
          some "[verification_requires_independence]" := by decide

/-- 未登録の theorem は none。 -/
example : lookupEquivalence "nonexistent_thm_xyz" = none := by decide

/-- 確認済 equivalent count = registry 全件 (Phase 5 acceptance)。 -/
example : confirmedEquivalent = 26 := by decide

end AgentSpec.Examples.SemanticEquivalence
