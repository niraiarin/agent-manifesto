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

## Scope progression

- Day 74 PoC: session_bounded のみ
- Day 80: no_cross_session_memory + session_no_shared_state 追加 (Ontology.lean に
  AuditEntry / Action / canTransition / Agent 追加とともに、T1 3 axiom 完備)

T1 は本来 3 axiom (session_bounded / no_cross_session_memory /
session_no_shared_state) で構成。Day 80 で全 3 axiom 移植完了、T1 stand-alone 達成。
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

/-- T1.2: No state sharing across sessions (causal independence of audit entries).

    Source: manifesto.md T1 "There is no continuous 'self'"
    Theoretical grounding: [R31] Milner CCS — parallel composition with
    no shared names = causal independence。
    Refutation condition: If session state could leak across process boundaries. -/
axiom no_cross_session_memory :
  ∀ (w : World) (e1 e2 : AuditEntry),
    e1 ∈ w.auditLog → e2 ∈ w.auditLog →
    e1.session ≠ e2.session →
    e1.preHash ≠ e2.postHash

/-- T1.3: No mutable state sharing across different sessions.

    Source: manifesto.md T1 "Each instance is an independent entity"
    Theoretical grounding: [R31] Milner CCS, [R32] Honda session types。
    Refutation condition: If inter-session communication channels existed. -/
axiom session_no_shared_state :
  ∀ (agent1 agent2 : Agent) (action1 action2 : Action)
    (w w' : World),
    action1.session ≠ action2.session →
    canTransition agent1 action1 w w' →
    (∃ w'', canTransition agent2 action2 w w'') →
    (∃ w''', canTransition agent2 action2 w' w''')

end AgentSpec.Manifest
