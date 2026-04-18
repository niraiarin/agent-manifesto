-- L1 Spine type class: 研究プロセスの状態遷移を抽象化
-- Day 8 で B4 Hoare 4-arg post に refactor 完了 (Section 2.9 完全解消)
-- Q4 案 A: transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop
import Init.Core
import AgentSpec.Process.Hypothesis
import AgentSpec.Provenance.Verdict

/-!
# AgentSpec.Spine.EvolutionStep: 研究プロセス状態遷移 type class (Day 8 で B4 4-arg post 完全統合)

G5-1 Section 3.4 ステップ 1 の `ResearchEvolutionStep` type class。
Day 3 hole-driven (transition 2-arg) → **Day 8 で B4 Hoare 4-arg post に完全 refactor**
(Section 2.9 完全解消、Section 2.14 Q4 案 A 確定)。

## 設計 (Day 8 確定: Q4 案 A)

    class EvolutionStep (S : Type u) where
      transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop

各引数の意味:
- `pre`: transition 前の state
- `input`: 主張 (Hypothesis、Process 層 Day 6)
- `output`: 検証結果 (Verdict、Provenance 層 Day 8)
- `post`: transition 後の state

これは G5-1 §3.4 の hypothesis / verdict / observation member 構想を **B4 Hoare 4-arg post**
パターンで統合した形。S4 P5 explicit assumptions 遵守 (Hypothesis/Verdict separate args)。

## 後方互換: `transitionLegacy` (deprecated 注記、Section 2.14 確定)

Day 1-7 で使われていた 2-arg `transition : S → S → Prop` は `transitionLegacy` に
rename して existential で derive:

    def transitionLegacy {S} [EvolutionStep S] (pre post : S) : Prop :=
      ∃ (h : Hypothesis) (v : Verdict), transition pre h v post

## 層依存性 (Day 8 で確定)

EvolutionStep (Spine 層) が Hypothesis (Process 層) と Verdict (Provenance 層) を import。
これは「Spine 層が下位層」という旧設計から「Spine 層が core abstraction、Process/Provenance
が具体型を提供」という新設計への shift。Q4 案 A 確定方針 (Section 2.14) に基づく。

## TyDD 原則 (Day 1-7 確立パターン適用)

- **Pattern #5** (def Prop signature): `transition` 4-arg post も Prop で hole-driven
- **Pattern #6** (sorry 0): Unit instance + transitionLegacy derive で完結
- **Pattern #7** (artifact-manifest 同 commit): Day 5 hook 化済、本 refactor も同 commit
- **Pattern #8** (Lean 4 予約語回避): `transition` / `transitionLegacy` ともに予約語ではない

## Day 8 意思決定ログ (Q4 案 A 反映)

### D1 (revised). type class member を 4-arg post に refactor (Q4 案 A)
- **代案 A** (Day 7 まで): `transition : S → S → Prop` (2-arg、abstract)
- **採用** (Day 8): `transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop`
  (4-arg post、S4 P5 explicit assumptions)
- **理由**: Section 2.9 完全解消、B4 Hoare 4-arg post パターン適用、
  G5-1 §3.4 hypothesis/verdict/observation 構想を 4-arg signature で統合表現。

### D2 (added Day 8). `transitionLegacy` を existential で derive
- **代案 A**: legacy を完全削除 (breaking change)
- **採用**: derive で残す (`∃ h v, transition pre h v post`)
- **理由**: Day 1-7 の TransitionReflexive / TransitionTransitive properties を維持、
  後方互換性確保 (Section 2.14 確定方針)。Day 9+ で必要時に deprecated 削除可能。

### D3 (revised). TransitionReflexive / TransitionTransitive を transitionLegacy ベースに
- **採用**: `∀ s, transitionLegacy s s` および `∀ a b c, transitionLegacy a b → transitionLegacy b c → transitionLegacy a c`
- **理由**: 4-arg post の reflexivity / transitivity は signature が複雑 (Hypothesis/Verdict も全称)、
  Day 8 minimal scope では legacy 版で properties を維持。Day 9+ で B4 4-arg properties 追加検討。

### D4. 層依存性 (Spine → Process / Provenance) を Q4 案 A で受容
- **採用**: EvolutionStep が Hypothesis (Process) と Verdict (Provenance) を import
- **理由**: G5-1 §3.4 設計通り (Hypothesis/Verdict が transition の input/output)、
  Spine 層は「core abstraction」、Process/Provenance は「具体型」という layer 役割再定義。
-/

universe u

namespace AgentSpec.Spine

open AgentSpec.Process (Hypothesis)
open AgentSpec.Provenance (Verdict)

/-- 研究プロセスの状態遷移を抽象化する type class (G5-1 §3.4 ステップ 1、Day 8 B4 4-arg post 完全統合)。

    transition は `(pre, input, output, post)` の 4-arg signature で、
    pre-state から post-state への遷移が input (Hypothesis) と output (Verdict) で
    特徴付けられる Hoare 4-arg post パターン (Q4 案 A 確定)。 -/
class EvolutionStep (S : Type u) where
  /-- B4 Hoare 4-arg post: pre から post への transition は input (Hypothesis) を受け
      output (Verdict) を返す関係 (S4 P5 explicit assumptions)。 -/
  transition : (pre : S) → (input : Hypothesis) → (output : Verdict) → (post : S) → Prop

namespace EvolutionStep

/-- Legacy 2-arg transition (Day 1-7 まで)。Day 8 で B4 4-arg post に refactor、
    legacy 形式は existential での derive (Section 2.14 D2)。
    Day 9+ で deprecated 削除候補。 -/
def transitionLegacy {S : Type u} [EvolutionStep S] (pre post : S) : Prop :=
  ∃ (h : Hypothesis) (v : Verdict), transition pre h v post

/-- transition の反射性 property (transitionLegacy ベース、Day 8 D3)。
    任意の state は自身に transition 可能 (Hypothesis/Verdict 存在)。 -/
def TransitionReflexive (S : Type u) [EvolutionStep S] : Prop :=
  ∀ s : S, transitionLegacy s s

/-- transition の推移性 property (transitionLegacy ベース、Day 8 D3)。 -/
def TransitionTransitive (S : Type u) [EvolutionStep S] : Prop :=
  ∀ a b c : S, transitionLegacy a b → transitionLegacy b c → transitionLegacy a c

end EvolutionStep

/-! ### Dummy instance for Unit (Day 8 で 4-arg post 対応に更新) -/

/-- `Unit` への dummy instance (Day 8 で 4-arg post 対応): 任意の transition を許可。 -/
instance instEvolutionStepUnit : EvolutionStep Unit where
  transition _ _ _ _ := True

/-- Unit instance の transition は常に True (decidable as `isTrue trivial`)。
    Day 4 cross-class test で `decide` を使うため明示的 Decidable instance を提供。
    Day 8 で 4-arg signature に更新。 -/
instance (a : Unit) (h : Hypothesis) (v : Verdict) (b : Unit) :
    Decidable (EvolutionStep.transition a h v b) :=
  isTrue trivial

end AgentSpec.Spine
