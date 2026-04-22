import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T2 (Week 3 Day 83、Manifest 移植)

T2 Structure Outlives the Agent — `structure_persists` + `structure_accumulates` の 2 axiom。

## Axiom Card (lean-formalization/Manifest/Axioms.lean line 216-244 から移植)

T2 は 2 axiom で構成:
1. **structure_persists**: 構造は session 終了後も永続 (persistence on file system)
2. **structure_accumulates**: epoch は単調増加 (Lamport monotonic clock)

## Theoretical grounding (T₀ environment constraint)

- [R34] Lamport (1978) "Time, Clocks, and the Ordering of Events" — 論理時計の単調性

## 降格判定

導出不可能 — `validTransition` が opaque のため、遷移後の structures 集合の単調性を
型から導出できない。axiom として維持。
-/

namespace AgentSpec.Manifest

/-- T2.1: Structure persists after session termination.

    Source: manifesto.md T2 "The place where improvements accumulate is within structure"
    Refutation condition: If persistent storage could lose data across valid transitions
    (e.g., volatile-only storage with no durability guarantee). -/
axiom structure_persists :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures

/-- T2.2: Structure accumulates improvements (epoch monotonic).

    Source: manifesto.md T2 "Structure accumulates improvements"
    Theoretical grounding: [R34] Lamport monotonic logical clock。
    Refutation condition: If epoch could decrease across valid transitions. -/
axiom structure_accumulates :
  ∀ (w w' : World),
    validTransition w w' →
    w.epoch ≤ w'.epoch

end AgentSpec.Manifest
