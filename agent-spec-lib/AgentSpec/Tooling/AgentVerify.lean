import Lean
import AgentSpec.Tooling.VerifyToken

/-\! # agent_verify tactic (Day 125 skeleton + Day 135 class-aware + PI-11 Day 154 二段検索)

検索順序 (preferred → fallback):
  1. **IsVerifyToken** instance lookup (object 層、kernel verifiable proof)
  2. **TrustDelegation** instance lookup (meta 層、外部 attestation、#print axioms 追跡可能)
  3. **assumption** fallback (従来動作維持)

二段検索 rationale (PI-11 Day 148 plan):
- IsVerifyToken と TrustDelegation を分離することで「object 層の証明」と「meta 層の attestation」が
  typeclass 構造で明示される (構文/意味 × 対象/メタ 評価弱点 #1 への structural 対処)
- agent_verify が両方を試すことで実用性は維持、provenance 区別は #print axioms で観察可能

GA-C26 (agent_verify tactic / VcForSkill VCG)、Phase 0 Week 5-6 entry。
-/

namespace AgentSpec.Tooling

open Lean Elab Tactic Meta

/-- `agent_verify` tactic (PI-11 Day 154、二段検索 class-aware 版)。
    1. IsVerifyToken (kernel proof) preferred、2. TrustDelegation (axiom-backed) fallback、3. assumption。 -/
elab "agent_verify" : tactic => withMainContext do
  let goal ← getMainGoal
  let goalType ← goal.getType
  -- 1. IsVerifyToken (preferred、kernel verifiable)
  let tokenType := mkApp (Lean.mkConst ``IsVerifyToken) goalType
  match (← try some <$> synthInstance tokenType catch _ => pure none) with
  | some inst =>
    goal.assign (mkProj ``IsVerifyToken 0 inst)
  | none =>
    -- 2. TrustDelegation (PI-11 fallback、axiom-backed、#print axioms で追跡可能)
    let trustType := mkApp (Lean.mkConst ``TrustDelegation) goalType
    match (← try some <$> synthInstance trustType catch _ => pure none) with
    | some inst =>
      goal.assign (mkProj ``TrustDelegation 0 inst)
    | none =>
      -- 3. assumption (legacy fallback)
      evalTactic (← `(tactic| assumption))

/-- Smoke test 1: assumption fallback (従来動作維持)。 -/
example (h : 1 + 1 = 2) : 1 + 1 = 2 := by agent_verify

/-- Smoke test 2: IsVerifyToken instance 経由 (Day 134 で `instance : IsVerifyToken (1 + 1 = 2)` 登録済)。 -/
example : 1 + 1 = 2 := by agent_verify

end AgentSpec.Tooling
