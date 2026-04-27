import AgentSpec
import Duper

/-! # Example 15: Duper integration baseline (Phase 7 sprint 1 #2)

Phase 7 sprint 1 acceptance #2: `Duper` integrated and proven on a minimal local theorem set.

Duper は superposition prover (proof-producing) で、equality reasoning と first-order shaped goal
が得意。Day 209 で lakefile に `require Duper from git ... @ "v4.29.0"` + `require auto from git ...
@ "v4.29.0-hammer"` を追加、lake update + build PASS (Duper 799 jobs)。

Day 209 Phase 7 sprint 1 #2 完成: integration 成功 + minimal theorem set で動作実証。
-/

namespace AgentSpec.Examples.DuperBaseline

/-- 命題論理: Duper は前提明示で trivial tautology を解く。 -/
example (p : Prop) : p → p := by duper [*]

/-- 連言の対称性: Duper は前提から equality + first-order で導出。 -/
example (p q : Prop) (h : p ∧ q) : q ∧ p := by duper [*]

/-- 選言の対称性: Duper は前提明示で対称性導出。 -/
example (p q : Prop) (h : p ∨ q) : q ∨ p := by duper [*]

/-- Modus ponens chain: 含意の transitive closure を Duper で解く。 -/
example (p q r : Prop) (hpq : p → q) (hqr : q → r) (hp : p) : r := by duper [*]

/-- 関数 equality: f x = y, g y = z から g (f x) = z を Duper で導出 (rewriting)。 -/
example (α β γ : Type) (f : α → β) (g : β → γ) (x : α) (y : β) (z : γ)
    (h1 : f x = y) (h2 : g y = z) : g (f x) = z := by duper [h1, h2]

/-- Day 209 Phase 7 sprint 1 #2 PoC pass count (5/5 baseline = 100%)。

Aesop と Duper の傾向比較 (Phase 7 sprint 3 で benchmark 化):
- Aesop: rfl + tauto + constructor 系 baseline 強い (Day 208 example 14)
- Duper: equality rewriting + first-order quantifier 強い (本 file)

Phase 7 sprint 1 で発見した Duper 使用上の制約 (sprint 3 failure taxonomy 候補):
- `by duper` 単独では context の hypothesis を automatic に集めない (`bare duper` failure)
- `by duper [*]` で local context 全 hypothesis を premise として渡す必要あり
- Aesop と異なり premise selection が caller 責務 (これは Duper の design choice、未来の retrieval-augmented 拡張余地) -/
def duperBaselinePassCount : Nat := 5

example : duperBaselinePassCount = 5 := by decide

end AgentSpec.Examples.DuperBaseline
