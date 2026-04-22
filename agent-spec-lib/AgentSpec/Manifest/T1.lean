import AgentSpec.Manifest.Ontology

/-! # AgentSpec.Manifest.T1 (Week 3 Day 74、PoC)

T1 Agent Sessions Are Ephemeral — `session_bounded` axiom (PoC scope: 1/3).

## Axiom Card (lean-formalization/Manifest/Axioms.lean line 83-103 から移植)

- **Layer**: T₀ (Environment-derived)
- **Content**: Sessions terminate in finite time. For all sessions, they
  become terminated at some point.
- **Basis**: Execution of computational agents consumes finite resources and
  therefore terminates in finite time (related to T7).

## Theoretical grounding (not formally proven — T₀ environment constraint)

[R33] Hoare (1978) "Communicating Sequential Processes" — Process termination:
a terminated process engages in no further events.

T₀ axioms encode physical facts, not mathematical theorems. Session boundedness
follows from finite resource consumption (T7).

## 降格判定

導出不可能 — `canTransition`, `validTransition` が opaque のため、有限時間
での終了を型から導出できない。axiom として維持。

## Day 74 PoC scope

T1 は本来 3 axiom (session_bounded / no_cross_session_memory /
session_no_shared_state) で構成。Day 74 では session_bounded のみ移植、
残 2 axiom は Day 75-76 で `AuditEntry` / `Action` / `canTransition`
opaque 追加とともに additive 拡張予定。
-/

namespace AgentSpec.Manifest

/-- T1.1: Sessions terminate in finite time (boundedness).

    Source: manifesto.md T1 "There is no memory across sessions"
    Refutation condition: If computational processes could run indefinitely
    without resource consumption (e.g., infinite energy source). -/
axiom session_bounded :
  ∀ (w : World) (s : Session),
    s ∈ w.sessions →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated

end AgentSpec.Manifest
