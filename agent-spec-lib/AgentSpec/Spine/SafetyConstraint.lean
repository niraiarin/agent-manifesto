-- L1 Spine type class: 安全境界の判定を抽象化
-- Day 3 hole-driven: safe : S → Bool (Bool 形式で完全 decidable)
-- Week 4-5 で `Decidable (safe_prop s)` 付きの Prop 形式に refactor 予定 (S4 P2)
import Init.Core

/-!
# AgentSpec.Spine.SafetyConstraint: L1 安全境界の type class

L1 manifesto (脅威認識・安全境界) を Lean 型として埋め込む基盤 (G5-1 §3.4 + G5-1 L1 章)。
SafeState refinement type は Day 2 評価 (Section 12.6) で識別された S4 P2 適用例。

## 設計

    class SafetyConstraint (S : Type u) where
      safe : S → Bool   -- Day 3 hole-driven (Bool で decidable)

    -- Week 4-5 refactor (S4 P2 Refinement, Section 2.8 と同思想):
    class SafetyConstraint (S : Type u) where
      safe : S → Prop
      safeDec : DecidablePred safe

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

    Day 3 hole-driven: `safe : S → Bool` で Bool 形式の decidable 判定。
    Week 4-5 で `Decidable (safe_prop s)` 付き Prop 形式に refactor 予定 (S4 P2)。 -/
class SafetyConstraint (S : Type u) where
  /-- 状態が L1 安全境界内かどうかの Bool 判定。
      Week 4-5 で `safe_prop : S → Prop` + `Decidable (safe_prop s)` に拡張予定。 -/
  safe : S → Bool

namespace SafetyConstraint

/-- S4 P2 Refinement type (Day 2 評価 Section 12.6 から導出)。

    `SafeState S` は `safe s = true` を満たす state のみを表す subtype。
    Edge.lean の no-self-loop refinement と同思想。

    `def` で Subtype の alias として定義。`.val` / `.property` は Subtype 標準 API
    として直接利用可能（ヘルパー toState/proof は不要、Subtype API 統一の方針）。

    Week 4-5 で Prop 形式 SafetyConstraint に refactor 後、
    `{ s : S // safe_prop s }` に進化予定。 -/
def SafeState (S : Type u) [SafetyConstraint S] : Type u :=
  { s : S // SafetyConstraint.safe s = true }

end SafetyConstraint

/-! ### Dummy instance for Unit (Day 3 hole-driven、Spine layer 最小 instance) -/

/-- `Unit` への dummy instance: 1 値しかない `()` を常に safe とする。 -/
instance instSafetyConstraintUnit : SafetyConstraint Unit where
  safe _ := true

end AgentSpec.Spine
