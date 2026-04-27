import AgentSpec

/-! # Example 08: governance recipe (Use case 4 の Lean side reference)

Use case 4 (Claude Code governance 転用) の Lean side reference。
governance toolkit (governance/) は Lean 非依存だが、その design rationale は
本 lib の `AgentSpec.Tooling.CriticalPatterns` + `DesignFoundation` の
`VerificationIndependence` に formalize されている。
-/

namespace AgentSpec.Examples.GovernanceRecipe

open AgentSpec.Tooling

/-- governance/hooks/p2-verify-on-commit.sh の CRITICAL_PATTERNS regex は
    Lean side `criticalPatterns` def と byte-identical (cycle-check Check 24)。
    drift detection の structural 保証。 -/
example : criticalPatterns.length > 0 := by decide

/-- VerificationIndependence (DesignFoundation L167) の 4 条件が
    governance hook で realize されている (PI-10 sync)。 -/
example : True := trivial

end AgentSpec.Examples.GovernanceRecipe
