import Lean
import AgentSpec.Tooling.VerifyToken
import AgentSpec.Tooling.AgentVerify

/-\!
# VerifyTokenMacro — token → IsVerifyToken instance auto-generation (Phase 0 Week 5-6、Day 137)

`verify_token <name> : <Prop>` macro で以下を一括生成:
1. `axiom <name> : <Prop>` (P2 verified by independent evaluator の trusted axiom)
2. `instance : IsVerifyToken <Prop> := ⟨<name>⟩` (agent_verify tactic detect 用)

これで Tooling chain の最終 link 完成: p2-verified.jsonl (Day 136 loader) で確認した
independent PASS token を、Lean 内で macro 1 行で構造化、agent_verify が auto discharge。

注意: 生成される axiom は **trusted** (kernel verify 外)、p2 hook の token と等価意味。
GA-C27 (trusted code 最小化) との trade-off を accept、token catalog で監視する設計。
-/

namespace AgentSpec.Tooling

/-- `verify_token <name> : <Prop>` syntax (command category 登録)。 -/
syntax "verify_token" ident ":" term : command

/-- macro_rules: axiom + IsVerifyToken instance を一括展開。 -/
macro_rules
  | `(verify_token $name:ident : $p:term) =>
    `(axiom $name : $p
      instance : IsVerifyToken $p := ⟨$name⟩)

end AgentSpec.Tooling

/-! ## Note on smoke testing

`verify_token` macro 自体の動作確認は別 test lib で実施 (本 file は macro 定義のみ)。
理由: macro は `axiom name : P` を生成するため、本 file で test すると trusted axiom が
production env に残り GA-C27 抵触 + 派生負債増加 → test は AgentSpecTest.lean 系で隔離。
-/
