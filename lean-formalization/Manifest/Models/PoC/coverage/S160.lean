/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalLaw** (ord=4): 流体力学の基礎法則（ナビエ-ストークス方程式等）。不変 [C1, C2]
- **ExperimentalProtocol** (ord=3): 風洞試験の手順・計測精度の制約 [C3, H1]
- **AnalysisMethod** (ord=2): データ解析・補正アルゴリズムの選択 [C4, H2, H3]
- **Visualization** (ord=1): 結果の可視化・レポート形式 [C5, H4, H5]
-/

namespace TestCoverage.S160

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s160_p01
  | s160_p02
  | s160_p03
  | s160_p04
  | s160_p05
  | s160_p06
  | s160_p07
  | s160_p08
  | s160_p09
  | s160_p10
  | s160_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s160_p01 => []
  | .s160_p02 => []
  | .s160_p03 => [.s160_p01]
  | .s160_p04 => [.s160_p01, .s160_p02]
  | .s160_p05 => [.s160_p03]
  | .s160_p06 => [.s160_p03, .s160_p04]
  | .s160_p07 => [.s160_p04]
  | .s160_p08 => [.s160_p05]
  | .s160_p09 => [.s160_p06]
  | .s160_p10 => [.s160_p07]
  | .s160_p11 => [.s160_p08, .s160_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 流体力学の基礎法則（ナビエ-ストークス方程式等）。不変 (ord=4) -/
  | PhysicalLaw
  /-- 風洞試験の手順・計測精度の制約 (ord=3) -/
  | ExperimentalProtocol
  /-- データ解析・補正アルゴリズムの選択 (ord=2) -/
  | AnalysisMethod
  /-- 結果の可視化・レポート形式 (ord=1) -/
  | Visualization
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalLaw => 4
  | .ExperimentalProtocol => 3
  | .AnalysisMethod => 2
  | .Visualization => 1

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
  bottom := .Visualization
  nontrivial := ⟨.PhysicalLaw, .Visualization, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalLaw
  | .s160_p01 | .s160_p02 => .PhysicalLaw
  -- ExperimentalProtocol
  | .s160_p03 | .s160_p04 => .ExperimentalProtocol
  -- AnalysisMethod
  | .s160_p05 | .s160_p06 | .s160_p07 => .AnalysisMethod
  -- Visualization
  | .s160_p08 | .s160_p09 | .s160_p10 | .s160_p11 => .Visualization

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

end TestCoverage.S160
