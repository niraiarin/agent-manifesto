-- L1 Spine type class: P3 学習サイクルを stage-indexed で抽象化
-- Day 4 hole-driven: LearningStage enum + valid transition + LearningCycle class
-- Week 4-5 で indexed monad (`LearningM (s : LearningStage) (α : Type u)`) に拡張予定 (G5-1 §3.4 ステップ 2)
import Init.Core
import AgentSpec.Spine.EvolutionStep
import AgentSpec.Spine.SafetyConstraint

/-!
# AgentSpec.Spine.LearningCycle: P3 学習サイクル type class

G5-1 §3.4 ステップ 2 の `LearningM` indexed monad の前段階。
Day 4 hole-driven で `LearningStage` enum + stage transition validity + class を実装。

## 設計 (G5-1 §3.4 ステップ 2)

    inductive LearningStage
      | Observation
      | Hypothesis
      | Verification
      | Integration
      | Retirement

    -- Week 4-5 (CSLib TimeM 類推):
    def LearningM (s : LearningStage) (α : Type u) : Type u := ...

    -- Day 4 (hole-driven):
    class LearningCycle (S : Type u) where
      currentStage : S → LearningStage

CSLib の TimeM monad の類推で V1-V7 メトリクスを値として持ち歩き、bind で
メトリクス変化を合成する。Day 4 では monad 化を未実施、stage 列挙と class のみ。

## TyDD 原則 (Day 1-3 確立パターン適用)

- **Pattern #5** (def Prop signature): `currentStage : S → LearningStage` は hole-driven
- **Pattern #6** (sorry 0): dummy instance for Unit のみで完結
- **Pattern #8** (Lean 4 予約語回避): `next` は予約語ではないが、`stage` は曖昧 → `currentStage` を採用

## Day 4 評価から導出 (Day 3 評価 Section 12.8 改善余地反映)

- **F2 Lattice (LearningCycle 収束)**: stage 順序 `LearningStage.le` で全順序を提供、
  Week 4-5 で `Lattice (Set LearningStage)` 拡張への基盤
- **cross-class interaction test** (Day 3 A2 残課題): LearningCycleTest 内で
  `[EvolutionStep S] [SafetyConstraint S] [LearningCycle S]` の同時要求を実演
- **H7 minimal viable pipeline**: L3 Lean のみで stage transition validity を `decide` 検証

## Day 4 意思決定ログ

### D1. `LearningStage` を inductive enum で実装
- **代案 A**: `Nat` で stage 番号化 (0=Observation, 4=Retirement)
- **採用**: inductive enum (5 variant)
- **理由**: TyDD-S1 types first 原則。意味のある名前を型レベルで保持。
  Edge.lean の EdgeKind 6 variant と同パターン (Day 2 D1 踏襲)。

### D2. `next` を total function で定義 (terminal stage は self-loop)
- **代案 A**: `Option LearningStage` で「次なし」を表現
- **採用**: `LearningStage → LearningStage` total、retirement は self-loop
- **理由**: 単純性。terminal 判定は `s = .retirement` で行う。
  Option の wrapper は cross-class 利用時に煩雑。

### D3. `le` を Bool 関数で定義 (Edge と同様、structural pattern reduction 回避)
- **代案 A**: Prop で半順序を定義
- **採用**: Bool 関数 + 暗黙の半順序意味論
- **理由**: `decide` で test を簡潔化。Day 5 で `LE LearningStage` instance 追加時に
  Prop 形式 (`compareOfLessAndEq`) を併設可能 (FolgeID パターン踏襲)。
-/

universe u

namespace AgentSpec.Spine

/-- P3 学習サイクルの 5 段階 (G5-1 §3.4 ステップ 2)。

    観察 → 仮説化 → 検証 → 統合 → 退役 の標準フロー。 -/
inductive LearningStage where
  | observation     -- 観察段階
  | hypothesis      -- 仮説化段階
  | verification    -- 検証段階
  | integration     -- 統合段階
  | retirement      -- 退役段階 (terminal)
  deriving DecidableEq, Inhabited, Repr

namespace LearningStage

/-- 次の段階への遷移 (forward-only)。retirement は self-loop。 -/
def next : LearningStage → LearningStage
  | .observation => .hypothesis
  | .hypothesis => .verification
  | .verification => .integration
  | .integration => .retirement
  | .retirement => .retirement

/-- 段階順序: `a.le b = true` ⇔ a が b と同等以前の段階。
    forward progression に基づく全順序 (terminal を除き strict)。 -/
def le : LearningStage → LearningStage → Bool
  | .observation, _ => true
  | .hypothesis, .observation => false
  | .hypothesis, _ => true
  | .verification, .observation => false
  | .verification, .hypothesis => false
  | .verification, _ => true
  | .integration, .observation => false
  | .integration, .hypothesis => false
  | .integration, .verification => false
  | .integration, _ => true
  | .retirement, .retirement => true
  | .retirement, _ => false

/-- terminal 判定: retirement は最終段階。 -/
def isTerminal : LearningStage → Bool
  | .retirement => true
  | _ => false

/-! ### Day 5: LE/LT/Decidable instance (FolgeID パターン踏襲、Section 2.10 + 2.11 対処)

    Day 4 評価 Section 2.11 🟡 F2 Lattice 部分対処として、Bool 関数 `le` を
    `LE`/`LT` instance に昇格。Decidable は `inferInstanceAs` で Bool 等価判定に委譲。
    Lattice instance は overspec として保留 (LearningStage 5 element の意味論固定が
    Week 4-5 まで未確定のため)。 -/

/-- LE instance: LearningStage の forward 全順序。`s.le = true` を Prop に昇格。
    FolgeID.instLE と同パターン (明示命名 + Bool 経由)。 -/
instance instLE : LE LearningStage := ⟨fun a b => a.le b = true⟩

/-- Decidable instance: Bool 等価判定に inferInstanceAs で委譲。
    unfold の脆弱性 (anonymous instance 名依存) を回避。 -/
instance (a b : LearningStage) : Decidable (a ≤ b) :=
  inferInstanceAs (Decidable (a.le b = true))

/-- LT instance: 厳密順序は le かつ ≠ で定義 (Mathlib LT/LE 標準パターン)。 -/
instance instLT : LT LearningStage := ⟨fun a b => a ≤ b ∧ a ≠ b⟩

/-- LT の Decidable instance: LE Decidable + DecidableEq の合成。 -/
instance (a b : LearningStage) : Decidable (a < b) :=
  inferInstanceAs (Decidable (a ≤ b ∧ a ≠ b))

end LearningStage

/-- P3 学習サイクル type class (G5-1 §3.4 ステップ 2)。

    Day 4 hole-driven: `currentStage` のみ。Week 4-5 で `LearningM` indexed monad に
    昇格、`bind`/`pure` で stage 進行を型レベル強制予定。 -/
class LearningCycle (S : Type u) where
  /-- 状態 `S` から現在の学習段階を抽出。 -/
  currentStage : S → LearningStage

/-! ### Dummy instance for Unit (Spine layer 最小 instance) -/

/-- `Unit` への dummy instance: 1 値しかない `()` は常に `observation` 段階。 -/
instance instLearningCycleUnit : LearningCycle Unit where
  currentStage _ := .observation

end AgentSpec.Spine
