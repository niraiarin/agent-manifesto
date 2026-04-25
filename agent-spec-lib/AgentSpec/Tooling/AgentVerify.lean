import Lean
import AgentSpec.Tooling.VerifyToken

/-\!
# agent_verify tactic (Phase 0 Week 5-6、Day 125 skeleton + Day 135 class-aware 拡張)

Day 135: IsVerifyToken (Day 134) class-aware に拡張。
  1. goal type に対する `IsVerifyToken` instance lookup を試行
  2. 成功 → instance.evidence で exact 適用 (verify token 由来 proof discharge)
  3. 失敗 → `assumption` fallback (従来動作維持)

GA-C26 (agent_verify tactic / VcForSkill VCG)、Phase 0 Week 5-6 entry。
将来拡張: `axiom verified_pass : ...` 形式の hypothesis pattern 検出、p2-verified.jsonl bridge。
-/

namespace AgentSpec.Tooling

open Lean Elab Tactic Meta

/-- `agent_verify` tactic (class-aware 版)。
    `IsVerifyToken (goalType)` instance が context にあれば evidence で exact 適用、
    なければ `assumption` fallback。 -/
elab "agent_verify" : tactic => withMainContext do
  let goal ← getMainGoal
  let goalType ← goal.getType
  -- IsVerifyToken instance lookup
  let tokenType := mkApp (Lean.mkConst ``IsVerifyToken) goalType
  match (← try some <$> synthInstance tokenType catch _ => pure none) with
  | some inst =>
    -- IsVerifyToken は単一 field (evidence : P) なので mkProj で取り出す
    goal.assign (mkProj ``IsVerifyToken 0 inst)
  | none =>
    evalTactic (← `(tactic| assumption))

/-- Smoke test 1: assumption fallback (従来動作維持)。 -/
example (h : 1 + 1 = 2) : 1 + 1 = 2 := by agent_verify

/-- Smoke test 2: IsVerifyToken instance 経由 (Day 134 で `instance : IsVerifyToken (1 + 1 = 2)` 登録済)。 -/
example : 1 + 1 = 2 := by agent_verify

end AgentSpec.Tooling
