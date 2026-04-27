-- L1 Spine type class: P4 可観測性 (V1-V7 metric tuple) を抽象化
-- Day 4 hole-driven: ObservableSnapshot structure + Observable class
-- Week 4-5 で V1-V7 個別 metric の型化 + 履歴 (TimeSeries) を追加予定
import Init.Core

/-!
# AgentSpec.Spine.Observable: P4 可観測性 type class

agent-manifesto の V1-V7 metric (`v1-tool-usage`, `v2-cycle-completion`, ...,
`v7-tasks`) を型レベルで抽象化。

## 設計 (G5-1 §3.4 + agent-manifesto P4)

    -- Day 4 (hole-driven): V1-V7 を共通 Nat tuple として表現
    structure ObservableSnapshot where
      v1 : Nat   -- tool usage count
      v2 : Nat   -- cycle completion
      v3 : Nat   -- approvals
      v4 : Nat   -- gate blocks
      v5 : Nat   -- approval ratio (* 100)
      v6 : Nat   -- compaction count
      v7 : Nat   -- 未処理タスク数

    class Observable (S : Type u) where
      snapshot : S → ObservableSnapshot

    -- Week 4-5 (拡張案):
    -- - V1-V7 を refinement type で個別宣言 (例: V5 は 0-100 の比率)
    -- - 時系列 `TimeSeries (s : LearningStage) (α : Type)` 追加
    -- - `LearningCycle.observation` member との合流

## TyDD 原則 (Day 1-3 確立パターン適用)

- **Pattern #5** (def Prop signature): Observable class は hole-driven
- **Pattern #6** (sorry 0): Unit dummy instance で完結
- **Pattern #8** (Lean 4 予約語回避): `snapshot` は予約語ではない

## Day 4 評価から導出 (Day 3 評価 Section 12.8)

- **F8 FiberedTypeSpec** (将来): `inductive Metric` で V1-V7 を fiber 化、
  `MetricObservation : (m : Metric) → Type` で metric ごと型を変える案 (Week 4-5)
- **B4 Hoare 4-arg post**: `snapshot` の前後変化を `(pre : S) → (action : A) → (post : S) → ObservableDelta` で表現 (Week 4-5)

## Day 4 意思決定ログ

### D1. ObservableSnapshot を Nat tuple で実装
- **代案 A**: V1-V7 を `inductive Metric` + `MetricValue (m : Metric) : Type` で fibered 化
- **採用**: 7-field structure (全て Nat)
- **理由**: Day 4 hole-driven の minimal 実装。F8 FiberedTypeSpec への昇格は
  Week 4-5 で metric ごとの value type が確定後 (例: V5 は Float / 0-100 比率)。

### D2. snapshot を `S → ObservableSnapshot` 直接関数で定義
- **代案 A**: `Observable` を `effectful` にして `S → IO ObservableSnapshot` で実時間取得
- **採用**: pure function `S → ObservableSnapshot`
- **理由**: 型レベルでの観測のみを Day 4 では抽象化。実時間取得の effect は
  Week 6-7 (CI/Tooling 層) で IO monad と統合。
-/

universe u

namespace AgentSpec.Spine

/-- agent-manifesto V1-V7 metric の snapshot (G5-1 §3.4 + agent-manifesto P4)。

    各 metric を Nat で表現 (Day 4 hole-driven)。Week 4-5 で個別 type 化予定。 -/
structure ObservableSnapshot where
  /-- V1: tool usage count -/
  v1 : Nat
  /-- V2: cycle completion -/
  v2 : Nat
  /-- V3: approvals -/
  v3 : Nat
  /-- V4: gate blocks -/
  v4 : Nat
  /-- V5: approval ratio (× 100、Day 4 では Nat) -/
  v5 : Nat
  /-- V6: compaction count -/
  v6 : Nat
  /-- V7: 未処理タスク数 -/
  v7 : Nat
  deriving DecidableEq, Inhabited, Repr

/-- P4 可観測性 type class: 状態 `S` から V1-V7 snapshot を抽出。 -/
class Observable (S : Type u) where
  /-- 現在状態の V1-V7 snapshot。 -/
  snapshot : S → ObservableSnapshot

/-! ### Dummy instance for Unit (Spine layer 最小 instance) -/

/-- `Unit` への dummy instance: 全 metric 0 の snapshot。 -/
instance instObservableUnit : Observable Unit where
  snapshot _ := { v1 := 0, v2 := 0, v3 := 0, v4 := 0, v5 := 0, v6 := 0, v7 := 0 }

end AgentSpec.Spine
