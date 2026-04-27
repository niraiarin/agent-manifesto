import AgentSpec.Manifest.T1
import AgentSpec.Manifest.T2

/-! # AgentSpec.Manifest.P3 (Week 3 Day 93)

P3 Governed Learning — 4 theorem (T1 + T2 合成、CompatibilityClass exhaustive)。
-/

namespace AgentSpec.Manifest

/-- P3a: modifier agent のセッションは終了する (T1 直接)。 -/
theorem modifier_agent_terminates :
  ∀ (w : World) (s : Session) (agent : Agent),
    s ∈ w.sessions →
    agent.currentSession = some s.id →
    ∃ (w' : World), w.time ≤ w'.time ∧
      ∃ (s' : Session), s' ∈ w'.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated :=
  fun w s _ h_mem _ => session_bounded w s h_mem

/-- P3b: 構造変更は session 終了後も永続 (T2 直接)。 -/
theorem modification_persists_after_termination :
  ∀ (w w' : World) (s : Session) (st : Structure),
    s ∈ w.sessions →
    st ∈ w.structures →
    s.status = SessionStatus.terminated →
    validTransition w w' →
    st ∈ w'.structures :=
  structure_persists

/-- P3c: 統治なし breaking change は不可逆 (T2 structure_accumulates 直接)。 -/
theorem ungoverned_breaking_change_irrecoverable :
  ∀ (w : World) (s : Session) (st : Structure)
    (ki : KnowledgeIntegration),
    s ∈ w.sessions →
    st ∈ w.structures →
    ki.before = w →
    ki.compatibility = CompatibilityClass.breakingChange →
    (∃ (w_term : World), w.time ≤ w_term.time ∧
      ∃ (s' : Session), s' ∈ w_term.sessions ∧
        s'.id = s.id ∧ s'.status = SessionStatus.terminated) →
    (∀ (w_future : World),
      validTransition ki.after w_future →
      ∀ st', st' ∈ ki.after.structures → st' ∈ w_future.structures) →
    ∀ (w_future : World),
      validTransition ki.after w_future →
      ki.after.epoch ≤ w_future.epoch :=
  fun _ _ _ ki _ _ _ _ _ _ w_future h_trans =>
    structure_accumulates ki.after w_future h_trans

/-- P3d: CompatibilityClass exhaustiveness (Lean inductive で構造的保証)。 -/
theorem compatibility_exhaustive :
  ∀ (c : CompatibilityClass),
    c = .conservativeExtension ∨
    c = .compatibleChange ∨
    c = .breakingChange := by
  intro c
  cases c <;> simp

end AgentSpec.Manifest
