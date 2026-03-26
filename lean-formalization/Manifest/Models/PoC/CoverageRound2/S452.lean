/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **StatisticalIntegrityInvariant** (ord=3): 国勢調査データの真正性・統計的不偏性の不変条件。データ改ざん・選択バイアス許容不可 [C1, C2]
- **DemographicModelPolicy** (ord=2): 出生率・死亡率・移動率モデルの選択方針。コーホート生命表・Leslie行列適用基準 [C3, H1, H2, H3]
- **ProjectionUncertaintyHypothesis** (ord=1): 長期予測誤差区間・感度分析・シナリオ分岐に関する不確実性仮説 [C4, H4, H5, H6, H7]
-/

namespace TestCoverage.S452

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s452_p01
  | s452_p02
  | s452_p03
  | s452_p04
  | s452_p05
  | s452_p06
  | s452_p07
  | s452_p08
  | s452_p09
  | s452_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s452_p01 => []
  | .s452_p02 => []
  | .s452_p03 => [.s452_p01]
  | .s452_p04 => [.s452_p01, .s452_p02]
  | .s452_p05 => [.s452_p03, .s452_p04]
  | .s452_p06 => [.s452_p03]
  | .s452_p07 => [.s452_p04, .s452_p05]
  | .s452_p08 => [.s452_p06]
  | .s452_p09 => [.s452_p07, .s452_p08]
  | .s452_p10 => [.s452_p08, .s452_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 国勢調査データの真正性・統計的不偏性の不変条件。データ改ざん・選択バイアス許容不可 (ord=3) -/
  | StatisticalIntegrityInvariant
  /-- 出生率・死亡率・移動率モデルの選択方針。コーホート生命表・Leslie行列適用基準 (ord=2) -/
  | DemographicModelPolicy
  /-- 長期予測誤差区間・感度分析・シナリオ分岐に関する不確実性仮説 (ord=1) -/
  | ProjectionUncertaintyHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .StatisticalIntegrityInvariant => 3
  | .DemographicModelPolicy => 2
  | .ProjectionUncertaintyHypothesis => 1

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
  bottom := .ProjectionUncertaintyHypothesis
  nontrivial := ⟨.StatisticalIntegrityInvariant, .ProjectionUncertaintyHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- StatisticalIntegrityInvariant
  | .s452_p01 | .s452_p02 => .StatisticalIntegrityInvariant
  -- DemographicModelPolicy
  | .s452_p03 | .s452_p04 | .s452_p05 => .DemographicModelPolicy
  -- ProjectionUncertaintyHypothesis
  | .s452_p06 | .s452_p07 | .s452_p08 | .s452_p09 | .s452_p10 => .ProjectionUncertaintyHypothesis

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

end TestCoverage.S452
