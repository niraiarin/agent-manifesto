/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **MaterialSafety** (ord=4): 材料の安全性・有害物質規制。RoHS/REACH等の法的要件 [C1, C2]
- **EngineeringStandard** (ord=3): JIS/ISO準拠の寸法精度・強度基準 [C3, H1]
- **ProcessParameter** (ord=2): 印刷パラメータの最適化ルール。材料・形状に依存 [C4, H2, H3]
- **DefectPrediction** (ord=1): 欠陥予測・品質改善の技術的仮説 [C5, H4, H5]
-/

namespace TestCoverage.S110

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s110_p01
  | s110_p02
  | s110_p03
  | s110_p04
  | s110_p05
  | s110_p06
  | s110_p07
  | s110_p08
  | s110_p09
  | s110_p10
  | s110_p11
  | s110_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s110_p01 => []
  | .s110_p02 => []
  | .s110_p03 => [.s110_p01]
  | .s110_p04 => [.s110_p01, .s110_p02]
  | .s110_p05 => [.s110_p02]
  | .s110_p06 => [.s110_p03]
  | .s110_p07 => [.s110_p04]
  | .s110_p08 => [.s110_p03, .s110_p05]
  | .s110_p09 => [.s110_p06]
  | .s110_p10 => [.s110_p07]
  | .s110_p11 => [.s110_p06, .s110_p08]
  | .s110_p12 => [.s110_p09, .s110_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 材料の安全性・有害物質規制。RoHS/REACH等の法的要件 (ord=4) -/
  | MaterialSafety
  /-- JIS/ISO準拠の寸法精度・強度基準 (ord=3) -/
  | EngineeringStandard
  /-- 印刷パラメータの最適化ルール。材料・形状に依存 (ord=2) -/
  | ProcessParameter
  /-- 欠陥予測・品質改善の技術的仮説 (ord=1) -/
  | DefectPrediction
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .MaterialSafety => 4
  | .EngineeringStandard => 3
  | .ProcessParameter => 2
  | .DefectPrediction => 1

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
  bottom := .DefectPrediction
  nontrivial := ⟨.MaterialSafety, .DefectPrediction, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- MaterialSafety
  | .s110_p01 | .s110_p02 => .MaterialSafety
  -- EngineeringStandard
  | .s110_p03 | .s110_p04 | .s110_p05 => .EngineeringStandard
  -- ProcessParameter
  | .s110_p06 | .s110_p07 | .s110_p08 => .ProcessParameter
  -- DefectPrediction
  | .s110_p09 | .s110_p10 | .s110_p11 | .s110_p12 => .DefectPrediction

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

end TestCoverage.S110
