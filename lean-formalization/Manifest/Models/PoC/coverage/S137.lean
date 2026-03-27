/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StructuralSafety** (ord=5): 橋梁の構造安全性。崩落リスクに直結する不変制約 [C1, C2]
- **InspectionStandard** (ord=4): 道路法・橋梁点検要領に基づく基準 [C3, H1]
- **DiagnosisMethod** (ord=3): 洗掘診断手法の設計。技術進歩で更新 [C4, H2]
- **MonitoringPolicy** (ord=2): 監視頻度・体制の運用方針。予算に応じて調整 [C5, H3]
- **PredictionHeuristic** (ord=1): 洗掘進行予測の仮説。観測データで検証 [H4, H5]
-/

namespace TestCoverage.S137

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s137_p01
  | s137_p02
  | s137_p03
  | s137_p04
  | s137_p05
  | s137_p06
  | s137_p07
  | s137_p08
  | s137_p09
  | s137_p10
  | s137_p11
  | s137_p12
  | s137_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s137_p01 => []
  | .s137_p02 => []
  | .s137_p03 => [.s137_p01]
  | .s137_p04 => [.s137_p01, .s137_p02]
  | .s137_p05 => [.s137_p03]
  | .s137_p06 => [.s137_p03, .s137_p04]
  | .s137_p07 => [.s137_p04]
  | .s137_p08 => [.s137_p05]
  | .s137_p09 => [.s137_p06]
  | .s137_p10 => [.s137_p05, .s137_p07]
  | .s137_p11 => [.s137_p08]
  | .s137_p12 => [.s137_p09]
  | .s137_p13 => [.s137_p10, .s137_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 橋梁の構造安全性。崩落リスクに直結する不変制約 (ord=5) -/
  | StructuralSafety
  /-- 道路法・橋梁点検要領に基づく基準 (ord=4) -/
  | InspectionStandard
  /-- 洗掘診断手法の設計。技術進歩で更新 (ord=3) -/
  | DiagnosisMethod
  /-- 監視頻度・体制の運用方針。予算に応じて調整 (ord=2) -/
  | MonitoringPolicy
  /-- 洗掘進行予測の仮説。観測データで検証 (ord=1) -/
  | PredictionHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StructuralSafety => 5
  | .InspectionStandard => 4
  | .DiagnosisMethod => 3
  | .MonitoringPolicy => 2
  | .PredictionHeuristic => 1

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
  bottom := .PredictionHeuristic
  nontrivial := ⟨.StructuralSafety, .PredictionHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StructuralSafety
  | .s137_p01 | .s137_p02 => .StructuralSafety
  -- InspectionStandard
  | .s137_p03 | .s137_p04 => .InspectionStandard
  -- DiagnosisMethod
  | .s137_p05 | .s137_p06 | .s137_p07 => .DiagnosisMethod
  -- MonitoringPolicy
  | .s137_p08 | .s137_p09 | .s137_p10 => .MonitoringPolicy
  -- PredictionHeuristic
  | .s137_p11 | .s137_p12 | .s137_p13 => .PredictionHeuristic

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

end TestCoverage.S137
