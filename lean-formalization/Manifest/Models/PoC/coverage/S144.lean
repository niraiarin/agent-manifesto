/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AnalyticalStandard** (ord=3): 分析化学の基準。計量トレーサビリティ・標準試料に基づく [C1, C2]
- **BiologicalKnowledge** (ord=2): 植物生理学・生化学の確立された知見 [C3, H1]
- **MethodSelection** (ord=1): 分析手法の選択。機器・コスト・目的に応じて変更可能 [C4, H2, H3]
- **PredictiveModel** (ord=0): 成分予測モデルの仮説。サンプルデータで検証が必要 [H4, H5]
-/

namespace TestCoverage.S144

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s144_p01
  | s144_p02
  | s144_p03
  | s144_p04
  | s144_p05
  | s144_p06
  | s144_p07
  | s144_p08
  | s144_p09
  | s144_p10
  | s144_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s144_p01 => []
  | .s144_p02 => []
  | .s144_p03 => [.s144_p01]
  | .s144_p04 => [.s144_p01, .s144_p02]
  | .s144_p05 => [.s144_p03]
  | .s144_p06 => [.s144_p04]
  | .s144_p07 => [.s144_p03, .s144_p04]
  | .s144_p08 => [.s144_p05]
  | .s144_p09 => [.s144_p06]
  | .s144_p10 => [.s144_p05, .s144_p07]
  | .s144_p11 => [.s144_p08, .s144_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 分析化学の基準。計量トレーサビリティ・標準試料に基づく (ord=3) -/
  | AnalyticalStandard
  /-- 植物生理学・生化学の確立された知見 (ord=2) -/
  | BiologicalKnowledge
  /-- 分析手法の選択。機器・コスト・目的に応じて変更可能 (ord=1) -/
  | MethodSelection
  /-- 成分予測モデルの仮説。サンプルデータで検証が必要 (ord=0) -/
  | PredictiveModel
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AnalyticalStandard => 3
  | .BiologicalKnowledge => 2
  | .MethodSelection => 1
  | .PredictiveModel => 0

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
  bottom := .PredictiveModel
  nontrivial := ⟨.AnalyticalStandard, .PredictiveModel, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AnalyticalStandard
  | .s144_p01 | .s144_p02 => .AnalyticalStandard
  -- BiologicalKnowledge
  | .s144_p03 | .s144_p04 => .BiologicalKnowledge
  -- MethodSelection
  | .s144_p05 | .s144_p06 | .s144_p07 => .MethodSelection
  -- PredictiveModel
  | .s144_p08 | .s144_p09 | .s144_p10 | .s144_p11 => .PredictiveModel

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

end TestCoverage.S144
