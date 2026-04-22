import AgentSpec.Manifest.E2

/-! # AgentSpec.Manifest.P1 (Week 3 Day 90、Manifest 移植 PoC)

P1 Autonomy and Vulnerability Co-scaling — theorem (E2 直接導出)。

## Scope progression

- Day 90 PoC: P1a (autonomy_vulnerability_coscaling) — E2 直接適用
- Day 91 拡張: P1b (unprotected_expansion_destroys_trust) — trust_decreases_on_materialized_risk 直接適用 (riskMaterialized + trustLevel 依存追加済)
-/

namespace AgentSpec.Manifest

/-- P1a: action space 拡大 → risk exposure 拡大 (E2 直接)。

    Source: manifesto.md P1 "Autonomy and Vulnerability Co-scaling"
    Derivation: capability_risk_coscaling (E2) 1 hop。 -/
theorem autonomy_vulnerability_coscaling :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskExposure agent w < riskExposure agent w' :=
  capability_risk_coscaling

/-- P1b: unprotected expansion (action space 拡大 + risk 顕在化) で trust 低下。

    Source: manifesto.md P1 "accumulated trust can be destroyed by a single incident"
    Derivation: trust_decreases_on_materialized_risk 直接適用。 -/
theorem unprotected_expansion_destroys_trust :
  ∀ (agent : Agent) (w w' : World),
    actionSpaceSize agent w < actionSpaceSize agent w' →
    riskMaterialized agent w' →
    trustLevel agent w' < trustLevel agent w :=
  trust_decreases_on_materialized_risk

end AgentSpec.Manifest
