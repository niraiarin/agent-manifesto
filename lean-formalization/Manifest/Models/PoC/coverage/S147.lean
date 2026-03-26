/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WeldStandard** (ord=3): 溶接品質基準。JIS・AWS規格に基づく合否判定基準 [C1, C2]
- **InspectionProtocol** (ord=2): 検査手順の確立された方法論。NDT(非破壊検査)の原理 [C3, H1]
- **SystemDesign** (ord=1): 検査システムの設計選択。機器構成・処理方式 [C4, C5, H2]
- **DetectionModel** (ord=0): 欠陥検出モデルの仮説。実溶接データで検証が必要 [H3, H4]
-/

namespace TestCoverage.S147

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s147_p01
  | s147_p02
  | s147_p03
  | s147_p04
  | s147_p05
  | s147_p06
  | s147_p07
  | s147_p08
  | s147_p09
  | s147_p10
  | s147_p11
  | s147_p12
  | s147_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s147_p01 => []
  | .s147_p02 => []
  | .s147_p03 => []
  | .s147_p04 => [.s147_p01]
  | .s147_p05 => [.s147_p02]
  | .s147_p06 => [.s147_p01, .s147_p03]
  | .s147_p07 => [.s147_p04]
  | .s147_p08 => [.s147_p05]
  | .s147_p09 => [.s147_p04, .s147_p06]
  | .s147_p10 => [.s147_p07]
  | .s147_p11 => [.s147_p08]
  | .s147_p12 => [.s147_p07, .s147_p09]
  | .s147_p13 => [.s147_p10, .s147_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 溶接品質基準。JIS・AWS規格に基づく合否判定基準 (ord=3) -/
  | WeldStandard
  /-- 検査手順の確立された方法論。NDT(非破壊検査)の原理 (ord=2) -/
  | InspectionProtocol
  /-- 検査システムの設計選択。機器構成・処理方式 (ord=1) -/
  | SystemDesign
  /-- 欠陥検出モデルの仮説。実溶接データで検証が必要 (ord=0) -/
  | DetectionModel
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WeldStandard => 3
  | .InspectionProtocol => 2
  | .SystemDesign => 1
  | .DetectionModel => 0

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
  bottom := .DetectionModel
  nontrivial := ⟨.WeldStandard, .DetectionModel, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WeldStandard
  | .s147_p01 | .s147_p02 | .s147_p03 => .WeldStandard
  -- InspectionProtocol
  | .s147_p04 | .s147_p05 | .s147_p06 => .InspectionProtocol
  -- SystemDesign
  | .s147_p07 | .s147_p08 | .s147_p09 => .SystemDesign
  -- DetectionModel
  | .s147_p10 | .s147_p11 | .s147_p12 | .s147_p13 => .DetectionModel

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

end TestCoverage.S147
