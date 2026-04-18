-- L1 Spine type class: 研究プロセスの状態遷移を抽象化
-- Day 3 hole-driven: transition member のみ。
-- Day 5 / Week 4-5 で hypothesis / verdict / observation を追加し
-- B4 Hoare 4-arg post pattern に拡張予定。
import Init.Core

/-!
# AgentSpec.Spine.EvolutionStep: 研究プロセス状態遷移 type class

G5-1 Section 3.4 ステップ 1 の `ResearchEvolutionStep` type class を hole-driven で実装。

## 設計 (G5-1 §3.4 + Section 10.2 / 12.6)

    class EvolutionStep (S : Type u) where
      transition : S → S → Prop          -- Day 3 (現状)
      hypothesis : S → Option Hypothesis -- Day 5 / Week 4-5
      verdict    : S → Option Verdict    -- Week 4-5
      observation : S → Observable       -- Week 4-5 (V1-V7 tuple)

CSLib の `LTS` を「研究プロセス」に specialize したもの。Cslib.Foundations.Semantics.LTS
への依存は GA-I5 により Week 6 まで延期、それまでは独自定義で代替。

## TyDD 原則 (Day 1-2 確立パターン適用)

- **Pattern #5** (def Prop signature): `transition : S → S → Prop` は hole-driven で先行
- **Pattern #6** (sorry 0): dummy instance for Unit のみで完結
- **Pattern #8** (Lean 4 予約語回避): `transition` は予約語ではない、`refl` は tactic 名と
  競合する可能性があるため `TransitionReflexive` と分離して定義

## Week 4-5 への遷移計画 (Day 2 評価から導出、Section 12.6)

- **B4 Hoare 4-arg post** 適用: `transition : (pre : S) → (input : I) → (output : O) → (post : S) → Prop`
  に拡張、frame condition を input/output で明示
- Hypothesis / Verdict / Observable type を定義し、type class member に追加
- `LearningCycle` (Day 4) との合成: indexed monad で stage transition を型レベル強制

## Day 3 意思決定ログ

### D1. type class member を `transition` のみに限定（Day 3 hole-driven）
- **代案 A**: G5-1 §3.4 通り 4 member 全実装
- **採用**: `transition` のみ
- **理由**: Hypothesis / Verdict / Observable 型未定義。dependent な仕様化は Week 4-5 で
  ResearchNode 系完備後に実施（Section 2.8 と同パターン）。

### D2. `transition_refl` を class member 外に定義
- **代案 A**: class member として `refl : ∀ s, transition s s` を追加
- **採用**: 別 def `TransitionReflexive : Prop` として宣言
- **理由**: `refl` は Lean 4 の tactic 名と shadow リスク（Pattern #8 の精神）。
  反射性は instance ごとに property として証明する形が safer。

### D3. dummy instance を `Unit` で実装
- **代案 A**: `Empty`, `Bool`, `Nat` 等
- **採用**: `Unit` (1 値のみ)
- **理由**: Spine layer の最小 instance としては `Unit` が標準。`transition () () := True` は
  trivially reflexive で、`TransitionReflexive Unit` の証明も自明。
-/

universe u

namespace AgentSpec.Spine

/-- 研究プロセスの状態遷移を抽象化する type class (G5-1 §3.4 ステップ 1)。

    Day 3 hole-driven: `transition` のみ。Day 5 / Week 4-5 で B4 Hoare 4-arg post への
    拡張と hypothesis / verdict / observation member の追加予定。 -/
class EvolutionStep (S : Type u) where
  /-- 状態遷移関係。pre → post の evolve 可能性を Prop で表現。
      Week 4-5 で `(pre : S) → (input : I) → (output : O) → (post : S) → Prop` に拡張予定。 -/
  transition : S → S → Prop

namespace EvolutionStep

/-- transition の反射性 property。任意の state は自身に transition 可能。
    instance ごとに証明・例示する形で利用 (class member 化は Day 5 / Week 4-5 検討)。 -/
def TransitionReflexive (S : Type u) [EvolutionStep S] : Prop :=
  ∀ s : S, transition s s

/-- transition の推移性 property。Day 5 拡充候補。 -/
def TransitionTransitive (S : Type u) [EvolutionStep S] : Prop :=
  ∀ a b c : S, transition a b → transition b c → transition a c

end EvolutionStep

/-! ### Dummy instance for Unit (Day 3 hole-driven、Spine layer 最小 instance) -/

/-- `Unit` への dummy instance: 任意の遷移を許可。 -/
instance instEvolutionStepUnit : EvolutionStep Unit where
  transition _ _ := True

/-- Unit instance の transition は常に True (decidable as `isTrue trivial`)。
    Day 4 cross-class test で `decide` を使うため明示的 Decidable instance を提供。 -/
instance (a b : Unit) : Decidable (EvolutionStep.transition a b) :=
  isTrue trivial

end AgentSpec.Spine
