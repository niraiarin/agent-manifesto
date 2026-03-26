/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **QualityStandard** (ord=5): 半導体品質規格（IEC/SEMI）に基づく不変基準 [C1, C2]
- **ProcessConstraint** (ord=4): 製造プロセスの物理的制約。装置仕様に依存 [C3, H1]
- **InspectionDesign** (ord=3): 検査手法の設計選択。技術進歩で更新可能 [C4, C5, H2]
- **ClassificationModel** (ord=2): 欠陥分類モデルの選択。精度データで改善 [C6, H3]
- **YieldHypothesis** (ord=1): 歩留まり改善の仮説。量産データで検証 [H4, H5]
-/

namespace TestCoverage.S140

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s140_p01
  | s140_p02
  | s140_p03
  | s140_p04
  | s140_p05
  | s140_p06
  | s140_p07
  | s140_p08
  | s140_p09
  | s140_p10
  | s140_p11
  | s140_p12
  | s140_p13
  | s140_p14
  | s140_p15
  | s140_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s140_p01 => []
  | .s140_p02 => []
  | .s140_p03 => []
  | .s140_p04 => [.s140_p01]
  | .s140_p05 => [.s140_p01, .s140_p02]
  | .s140_p06 => [.s140_p04]
  | .s140_p07 => [.s140_p04, .s140_p05]
  | .s140_p08 => [.s140_p05]
  | .s140_p09 => [.s140_p06]
  | .s140_p10 => [.s140_p07]
  | .s140_p11 => [.s140_p06, .s140_p08]
  | .s140_p12 => [.s140_p09]
  | .s140_p13 => [.s140_p10]
  | .s140_p14 => [.s140_p09, .s140_p11]
  | .s140_p15 => [.s140_p03]
  | .s140_p16 => [.s140_p10, .s140_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 半導体品質規格（IEC/SEMI）に基づく不変基準 (ord=5) -/
  | QualityStandard
  /-- 製造プロセスの物理的制約。装置仕様に依存 (ord=4) -/
  | ProcessConstraint
  /-- 検査手法の設計選択。技術進歩で更新可能 (ord=3) -/
  | InspectionDesign
  /-- 欠陥分類モデルの選択。精度データで改善 (ord=2) -/
  | ClassificationModel
  /-- 歩留まり改善の仮説。量産データで検証 (ord=1) -/
  | YieldHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .QualityStandard => 5
  | .ProcessConstraint => 4
  | .InspectionDesign => 3
  | .ClassificationModel => 2
  | .YieldHypothesis => 1

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
  bottom := .YieldHypothesis
  nontrivial := ⟨.QualityStandard, .YieldHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- QualityStandard
  | .s140_p01 | .s140_p02 | .s140_p03 => .QualityStandard
  -- ProcessConstraint
  | .s140_p04 | .s140_p05 => .ProcessConstraint
  -- InspectionDesign
  | .s140_p06 | .s140_p07 | .s140_p08 => .InspectionDesign
  -- ClassificationModel
  | .s140_p09 | .s140_p10 | .s140_p11 => .ClassificationModel
  -- YieldHypothesis
  | .s140_p12 | .s140_p13 | .s140_p14 | .s140_p15 | .s140_p16 => .YieldHypothesis

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

end TestCoverage.S140
