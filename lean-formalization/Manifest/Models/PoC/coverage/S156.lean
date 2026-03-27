/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **TransportRegulation** (ord=4): 道路運送法・労基法等の法的制約。変更不可 [C1, C2]
- **DemandAnalysis** (ord=3): 乗客需要の分析に基づく運行方針 [C3, H1, H2]
- **ScheduleDesign** (ord=2): 時刻表・車両配置の設計最適化 [C4, H3]
- **RealTimeAdjustment** (ord=1): リアルタイムの遅延対応・運行調整 [C5, H4, H5]
-/

namespace TestCoverage.S156

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s156_p01
  | s156_p02
  | s156_p03
  | s156_p04
  | s156_p05
  | s156_p06
  | s156_p07
  | s156_p08
  | s156_p09
  | s156_p10
  | s156_p11
  | s156_p12
  | s156_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s156_p01 => []
  | .s156_p02 => []
  | .s156_p03 => []
  | .s156_p04 => [.s156_p01]
  | .s156_p05 => [.s156_p02]
  | .s156_p06 => [.s156_p01, .s156_p03]
  | .s156_p07 => [.s156_p04]
  | .s156_p08 => [.s156_p05, .s156_p06]
  | .s156_p09 => [.s156_p04]
  | .s156_p10 => [.s156_p07]
  | .s156_p11 => [.s156_p08]
  | .s156_p12 => [.s156_p09]
  | .s156_p13 => [.s156_p10, .s156_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 道路運送法・労基法等の法的制約。変更不可 (ord=4) -/
  | TransportRegulation
  /-- 乗客需要の分析に基づく運行方針 (ord=3) -/
  | DemandAnalysis
  /-- 時刻表・車両配置の設計最適化 (ord=2) -/
  | ScheduleDesign
  /-- リアルタイムの遅延対応・運行調整 (ord=1) -/
  | RealTimeAdjustment
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .TransportRegulation => 4
  | .DemandAnalysis => 3
  | .ScheduleDesign => 2
  | .RealTimeAdjustment => 1

/-- 認識論的層構造の typeclass（スタンドアロン版）。 -/
class EpistemicLayerClass (α : Type) where
  ord : α → Nat
  bottom : α
  nontrivial : ∃ (a b : α), ord a ≠ ord b
  ord_injective : ∀ (a b : α), ord a = ord b → a = b
  ord_bounded : ∃ (n : Nat), ∀ (a : α), ord a ≤ n
  bottom_minimum : ∀ (a : α), ord bottom ≤ ord a

instance : EpistemicLayerClass ConcreteLayer where
  ord := ConcreteLayer.ord
  bottom := .RealTimeAdjustment
  nontrivial := ⟨.TransportRegulation, .RealTimeAdjustment, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- TransportRegulation
  | .s156_p01 | .s156_p02 | .s156_p03 => .TransportRegulation
  -- DemandAnalysis
  | .s156_p04 | .s156_p05 | .s156_p06 => .DemandAnalysis
  -- ScheduleDesign
  | .s156_p07 | .s156_p08 | .s156_p09 => .ScheduleDesign
  -- RealTimeAdjustment
  | .s156_p10 | .s156_p11 | .s156_p12 | .s156_p13 => .RealTimeAdjustment

-- ============================================================
-- 4. 証明
-- ============================================================

/-- classify は依存関係の単調性を尊重する。 -/
theorem classify_monotone :
    ∀ (a b : PropositionId),
      propositionDependsOn a b = true →
      ConcreteLayer.ord (classify b) ≥ ConcreteLayer.ord (classify a) := by
  intro a b h; cases a <;> cases b <;> revert h <;> native_decide

/-- classify は全域関数。 -/
theorem classify_total :
    ∀ (p : PropositionId), ∃ (l : ConcreteLayer), classify p = l :=
  fun p => ⟨classify p, rfl⟩

end TestCoverage.S156
