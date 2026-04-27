-- L1 Spine type class: 安全境界の判定を抽象化
-- Day 4: Bool→Prop refactor 完了 (Day 3 評価 Section 2.9 🔴 を前倒し対処)
-- `safe : S → Prop` + bundled `safeDec : DecidablePred safe` で
-- Prop の generality と decide の自動化を両立 (S4 P2 / S1 #9 強化)
import Init.Core

/-!
# AgentSpec.Spine.SafetyConstraint: L1 安全境界の type class

L1 manifesto (脅威認識・安全境界) を Lean 型として埋め込む基盤 (G5-1 §3.4 + G5-1 L1 章)。
SafeState refinement type は Day 2 評価 (Section 12.6) で識別された S4 P2 適用例。

## 設計 (Day 4 で Prop 形式完了)

    class SafetyConstraint (S : Type u) where
      safe : S → Prop
      safeDec : DecidablePred safe   -- bundled Decidable for `decide` automation

    attribute [reducible, instance] SafetyConstraint.safeDec
    -- → reducible: class field を global instance に lift する際必要 (Lean 4 警告対処)
    -- → instance: 自動 type class resolution に組込み

旧 Bool 形式 (Day 3): `safe : S → Bool` は Day 4 で Prop へ refactor。
理由は Day 3 評価 Section 2.9 🔴 の S1 benefit #9 影響。

## TyDD 原則 (Day 1-2 確立パターン適用)

- **Pattern #5** (def Prop signature): SafeState は subtype として hole-driven 定義
- **Pattern #6** (sorry 0): dummy instance は `safe _ := true` で trivial
- **Pattern #7** (artifact-manifest 同 commit): 別 commit で対処予定 (Section 6.2.1 hook 化検討中)

## Day 2 評価から導出 (Section 12.6 改善余地)

- **S4 P2 Refinement (高優先)**: SafeState subtype は型レベルで安全な state のみを
  許容する refinement type。Edge.lean の no-self-loop と同思想。
- Day 3 では Bool 形式で hole-driven 開始、Week 4-5 で `Decidable` 付き Prop 形式へ昇格。

## Day 3 意思決定ログ

### D1. Bool 形式を採用 (vs Prop + Decidable)
- **代案 A**: `safe : S → Prop` + `safeDec : DecidablePred safe`
- **採用**: `safe : S → Bool`
- **理由**: Day 3 hole-driven 段階。Bool 形式は `decide` 不要で example assertion が
  単純化される。Prop 形式への昇格は SafeState refinement と同時に Week 4-5 で実施。

### D2. SafeState を subtype `{ s // safe s = true }` で定義
- **代案 A**: 別 inductive `inductive SafeState (S : Type u) [SafetyConstraint S]`
- **採用**: subtype 形式
- **理由**: Lean 4 の subtype は extracting `s.val` / `s.property` が標準的で、
  Mathlib の `Subtype` API が直接利用可能。Refinement type の標準的表現。

### D3. dummy instance を Unit で実装 (常に safe)
- **代案 A**: `Empty` (常に safe だが空)、`Bool` (true/false で実例ある)
- **採用**: `Unit` (1 値、常に safe)
- **理由**: EvolutionStep と同じ instance 戦略で Spine layer の uniform 化。
  Unit の SafeState `⟨(), rfl⟩` は inhabited を trivially 示せる。
-/

universe u

namespace AgentSpec.Spine

/-- L1 安全境界判定の type class (G5-1 §3.4 + L1 manifesto)。

    Day 4 で Bool→Prop refactor 完了 (Day 3 評価 Section 2.9 🔴 を前倒し対処)。
    `safe : S → Prop` + bundled `safeDec : DecidablePred safe` で
    Prop の generality と decide の自動化を両立 (S4 P2 / S1 benefit #9 強化)。 -/
class SafetyConstraint (S : Type u) where
  /-- 状態が L1 安全境界内かどうかを Prop で判定。 -/
  safe : S → Prop
  /-- safety predicate の decidability。`decide` で auto-evaluation 可能。 -/
  safeDec : DecidablePred safe

attribute [reducible, instance] SafetyConstraint.safeDec

namespace SafetyConstraint

/-- S4 P2 Refinement type (Day 2 評価 Section 12.6 から導出、Day 4 で Prop 形式化)。

    `SafeState S` は `safe s` (Prop) を満たす state のみを表す subtype。
    Edge.lean の no-self-loop refinement と同思想。

    `def` で Subtype の alias として定義。`.val` / `.property` は Subtype 標準 API
    として直接利用可能。 -/
def SafeState (S : Type u) [SafetyConstraint S] : Type u :=
  { s : S // SafetyConstraint.safe s }

/-- Smart constructor (Day 3 評価 Section 2.9 🟡 を前倒し対処)。

    `SafeState.mk s h` で safety proof と共に SafeState を構築。
    `⟨s, h⟩` の Subtype anonymous constructor 直接呼び出しよりも intent が明示的。 -/
def SafeState.mk {S : Type u} [SafetyConstraint S] (s : S) (h : SafetyConstraint.safe s) :
    SafeState S :=
  ⟨s, h⟩

end SafetyConstraint

/-! ### Dummy instance for Unit (Spine layer 最小 instance、Day 4 で Prop 形式に更新) -/

/-- `Unit` への dummy instance: 1 値しかない `()` を常に safe とする (Prop = True)。 -/
instance instSafetyConstraintUnit : SafetyConstraint Unit where
  safe _ := True
  safeDec _ := isTrue True.intro

end AgentSpec.Spine
