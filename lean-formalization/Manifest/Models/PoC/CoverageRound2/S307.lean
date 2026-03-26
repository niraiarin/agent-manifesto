/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **QualityInvariant** (ord=4): 製品出荷品質保証に関する絶対不変条件（偽陰性ゼロ） [C1, C2]
- **InspectionStandard** (ord=3): IPC基準・顧客仕様への適合検査方針 [C3, C4]
- **DetectionModel** (ord=2): 欠陥分類・サイズ測定・位置特定のモデル [C5, H1, H2]
- **DefectHypothesis** (ord=1): 欠陥発生パターン・製造工程起因推定の仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S307

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s307_p01
  | s307_p02
  | s307_p03
  | s307_p04
  | s307_p05
  | s307_p06
  | s307_p07
  | s307_p08
  | s307_p09
  | s307_p10
  | s307_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s307_p01 => []
  | .s307_p02 => [.s307_p01]
  | .s307_p03 => [.s307_p01]
  | .s307_p04 => [.s307_p02, .s307_p03]
  | .s307_p05 => [.s307_p03]
  | .s307_p06 => [.s307_p04]
  | .s307_p07 => [.s307_p05, .s307_p06]
  | .s307_p08 => [.s307_p05]
  | .s307_p09 => [.s307_p06]
  | .s307_p10 => [.s307_p07, .s307_p08]
  | .s307_p11 => [.s307_p09, .s307_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 製品出荷品質保証に関する絶対不変条件（偽陰性ゼロ） (ord=4) -/
  | QualityInvariant
  /-- IPC基準・顧客仕様への適合検査方針 (ord=3) -/
  | InspectionStandard
  /-- 欠陥分類・サイズ測定・位置特定のモデル (ord=2) -/
  | DetectionModel
  /-- 欠陥発生パターン・製造工程起因推定の仮説 (ord=1) -/
  | DefectHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .QualityInvariant => 4
  | .InspectionStandard => 3
  | .DetectionModel => 2
  | .DefectHypothesis => 1

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
  bottom := .DefectHypothesis
  nontrivial := ⟨.QualityInvariant, .DefectHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- QualityInvariant
  | .s307_p01 | .s307_p02 => .QualityInvariant
  -- InspectionStandard
  | .s307_p03 | .s307_p04 => .InspectionStandard
  -- DetectionModel
  | .s307_p05 | .s307_p06 | .s307_p07 => .DetectionModel
  -- DefectHypothesis
  | .s307_p08 | .s307_p09 | .s307_p10 | .s307_p11 => .DefectHypothesis

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

end TestCoverage.S307
