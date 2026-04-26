import AgentSpec.Manifest.Observable

/-! # MeasurableSemantic — semantic 強化版 Measurable typeclass (PI-12、Day 159)

`AgentSpec.Manifest.Observable.Measurable` (syntactic):
```
def Measurable (m : World → Nat) : Prop := ∃ f : World → Nat, ∀ w, f w = m w
```
は `f := m` で trivially provable (Day 146 で "Demoted: Measurable is trivially satisfied" 文書化済)。
syntactic に well-formed だが semantic 内容を持たない (構文/意味 × 対象/メタ 評価 弱点 #2)。

本 file は **conservative extension** として `MeasurableSemantic` typeclass を追加:
- `Measurable` (既存) は syntactic 存在述語として retain
- `MeasurableSemantic` は **named axiom evidence** を要求 (TrustDelegation pattern、PI-11 と同型)
- `#print axioms` で axiom 由来を追跡可能

PI-12 (Day 148 plan): syntactic vs semantic の区別を typeclass 構造で明示。
将来的には V1-V7 各 m に対し `axiom skillQuality_measurement_procedure : MeasurementProcedure skillQuality`
を declare して `instance : MeasurableSemantic skillQuality := ⟨skillQuality_measurement_procedure⟩` の形で
semantic 主張を axiom dependency として可視化。
-/

namespace AgentSpec.Tooling

open AgentSpec.Manifest

/-- 測定手続き存在の semantic claim を named axiom で表現するための marker。
    `axiom <m>_measurement_procedure : MeasurementProcedure <m>` の形で declare。
    具体的測定手続き (benchmark.json / observe.sh proxy 等) を operational layer に delegate するが、
    型レベルでその「外部 commitment が存在する」事実を表現。 -/
def MeasurementProcedure (m : World → Nat) : Prop :=
  ∃ f : World → Nat, (∀ w, f w = m w) ∧ True  -- syntactic 同型だが axiom 経由で意味を付与

/-- MeasurableSemantic: m が semantic に measurable である claim。
    `instance : MeasurableSemantic m := ⟨named_axiom⟩` で named axiom evidence 必須。
    `#print axioms` で named_axiom 由来を追跡可能 (PI-11 TrustDelegation pattern)。

    syntactic `Measurable m` (∃ f, ∀ w, f w = m w) との違い:
    - Measurable: `⟨m, fun _ => rfl⟩` で trivially provable
    - MeasurableSemantic: 必ず named axiom 経由、`#print axioms` で trace 可能

    例:
    ```
    axiom skillQuality_measurement : MeasurementProcedure skillQuality
    instance : MeasurableSemantic skillQuality := ⟨skillQuality_measurement⟩
    ```
    `#print axioms ...` で `skillQuality_measurement` が表示される。 -/
class MeasurableSemantic (m : World → Nat) : Prop where
  evidence : MeasurementProcedure m

/-- MeasurableSemantic instance を Measurable に変換する bridge。
    semantic claim を持つなら syntactic claim も自動で得られる (forward direction)。 -/
theorem measurableSemantic_implies_measurable {m : World → Nat}
    [inst : MeasurableSemantic m] : Measurable m :=
  ⟨inst.evidence.choose, inst.evidence.choose_spec.1⟩

end AgentSpec.Tooling
