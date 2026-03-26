/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalConstraint** (ord=3): 海洋環境・漁業規制に関する不変前提 [C1, C2]
- **BiologicalEvidence** (ord=2): 海藻の生育に関する科学的知見。新データで更新されうる [C3, H1, H2]
- **CultivationDesign** (ord=1): 養殖手法・設備の設計選択。コスト・効率のトレードオフ [C4, C5, H3, H4]
- **GrowthHypothesis** (ord=0): 収穫量・品質に関する未検証仮説。実地試験で確認が必要 [H5, H6]
-/

namespace TestCoverage.S183

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s183_p01
  | s183_p02
  | s183_p03
  | s183_p04
  | s183_p05
  | s183_p06
  | s183_p07
  | s183_p08
  | s183_p09
  | s183_p10
  | s183_p11
  | s183_p12
  | s183_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s183_p01 => []
  | .s183_p02 => []
  | .s183_p03 => [.s183_p01]
  | .s183_p04 => [.s183_p01]
  | .s183_p05 => [.s183_p01, .s183_p02]
  | .s183_p06 => [.s183_p03]
  | .s183_p07 => [.s183_p04]
  | .s183_p08 => [.s183_p03, .s183_p05]
  | .s183_p09 => [.s183_p04]
  | .s183_p10 => [.s183_p06]
  | .s183_p11 => [.s183_p07, .s183_p08]
  | .s183_p12 => [.s183_p09]
  | .s183_p13 => [.s183_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋環境・漁業規制に関する不変前提 (ord=3) -/
  | EnvironmentalConstraint
  /-- 海藻の生育に関する科学的知見。新データで更新されうる (ord=2) -/
  | BiologicalEvidence
  /-- 養殖手法・設備の設計選択。コスト・効率のトレードオフ (ord=1) -/
  | CultivationDesign
  /-- 収穫量・品質に関する未検証仮説。実地試験で確認が必要 (ord=0) -/
  | GrowthHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalConstraint => 3
  | .BiologicalEvidence => 2
  | .CultivationDesign => 1
  | .GrowthHypothesis => 0

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
  bottom := .GrowthHypothesis
  nontrivial := ⟨.EnvironmentalConstraint, .GrowthHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalConstraint
  | .s183_p01 | .s183_p02 => .EnvironmentalConstraint
  -- BiologicalEvidence
  | .s183_p03 | .s183_p04 | .s183_p05 => .BiologicalEvidence
  -- CultivationDesign
  | .s183_p06 | .s183_p07 | .s183_p08 | .s183_p09 => .CultivationDesign
  -- GrowthHypothesis
  | .s183_p10 | .s183_p11 | .s183_p12 | .s183_p13 => .GrowthHypothesis

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

end TestCoverage.S183
