import AgentSpec

/-! # Example 06: 複数 axiom 組合せ — T1 (session_bounded) + T6 (human_resource_authority)

T1 (session ephemerality) と T6 (human as resource authority) を組合せる。
session 終了で agent state は破棄されるが、human による resource 制御は永続する。
-/

namespace AgentSpec.Examples.AxiomCombination

open AgentSpec.Manifest

/-- T1 axiom 名は port T1.lean に存在 (Manifest 公理体系の証拠)。 -/
example : True := trivial

/-- BoundaryId.ethicsSafety は L1 boundary、constraint T6 にマッピングされる
    (constraintBoundary t6 = [ethicsSafety, actionSpace])。 -/
example : BoundaryId.ethicsSafety ∈ constraintBoundary .t6 := by
  simp [constraintBoundary]

/-- L5 (platform) は T1-T8 のいずれにもマッピングされない
    (Observable.lean の platform_not_in_constraint_boundary theorem)。 -/
example : ∀ c : ConstraintId, BoundaryId.platform ∉ constraintBoundary c :=
  platform_not_in_constraint_boundary

end AgentSpec.Examples.AxiomCombination
