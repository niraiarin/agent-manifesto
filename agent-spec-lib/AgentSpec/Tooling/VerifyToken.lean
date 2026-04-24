import Lean

/-\!
# IsVerifyToken — Verify Token typeclass (Phase 0 Week 5-6、Day 134)

P2 verification token を Lean type system で構造化。
独立 evaluator (Ollama / 別 API / 人間) 由来の verification を Lean instance として表現、
agent_verify tactic (Day 125) と将来 integrate して proof discharge を automate する基盤。

将来拡張:
- p2-verified.jsonl の token を Lean instance に変換する macro
- agent_verify tactic 拡張で IsVerifyToken instance を context から自動 detect、exact 適用
- VcForSkill VCG (Day 127) と組合せて proof obligation の verify token 化
-/

namespace AgentSpec.Tooling

/-- Verify token typeclass。
    `instance : IsVerifyToken P := ⟨proof⟩` で「P は independent evaluator により verified」を marker 化。 -/
class IsVerifyToken (P : Prop) : Prop where
  evidence : P

/-- IsVerifyToken instance を proof として展開する helper。 -/
def verifyTokenProof {P : Prop} [inst : IsVerifyToken P] : P :=
  inst.evidence

/-- Smoke test: trivial proposition への IsVerifyToken instance。 -/
instance : IsVerifyToken (1 + 1 = 2) := ⟨rfl⟩

/-- Smoke test: IsVerifyToken instance を verifyTokenProof で展開して theorem を証明。 -/
theorem one_plus_one_verified : 1 + 1 = 2 :=
  verifyTokenProof

end AgentSpec.Tooling
