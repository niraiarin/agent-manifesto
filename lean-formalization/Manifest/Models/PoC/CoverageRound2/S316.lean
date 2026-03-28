/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **accuracy_requirement** (ord=3): 予測精度・不確実性定量化の要件 [C1, C2, C4]
- **data_integration_model** (ord=2): 多源データ統合・配信インターフェース [C3, C5, H1]
- **modeling_hypothesis** (ord=1): モデルアーキテクチャ・学習戦略の仮説 [H2, H3, H4, H5]
-/

namespace TestCoverage.S316

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s316_p01
  | s316_p02
  | s316_p03
  | s316_p04
  | s316_p05
  | s316_p06
  | s316_p07
  | s316_p08
  | s316_p09
  | s316_p10
  | s316_p11
  | s316_p12
  | s316_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s316_p01 => []
  | .s316_p02 => [.s316_p01]
  | .s316_p03 => [.s316_p01]
  | .s316_p04 => [.s316_p01]
  | .s316_p05 => [.s316_p04]
  | .s316_p06 => [.s316_p04]
  | .s316_p07 => [.s316_p02, .s316_p06]
  | .s316_p08 => [.s316_p03, .s316_p06]
  | .s316_p09 => [.s316_p04, .s316_p08]
  | .s316_p10 => [.s316_p05, .s316_p09]
  | .s316_p11 => [.s316_p04, .s316_p06]
  | .s316_p12 => [.s316_p08, .s316_p09]
  | .s316_p13 => [.s316_p01, .s316_p02]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 予測精度・不確実性定量化の要件 (ord=3) -/
  | accuracy_requirement
  /-- 多源データ統合・配信インターフェース (ord=2) -/
  | data_integration_model
  /-- モデルアーキテクチャ・学習戦略の仮説 (ord=1) -/
  | modeling_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .accuracy_requirement => 3
  | .data_integration_model => 2
  | .modeling_hypothesis => 1

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
  bottom := .modeling_hypothesis
  nontrivial := ⟨.accuracy_requirement, .modeling_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- accuracy_requirement
  | .s316_p01 | .s316_p02 | .s316_p03 | .s316_p13 => .accuracy_requirement
  -- data_integration_model
  | .s316_p04 | .s316_p05 | .s316_p06 | .s316_p11 => .data_integration_model
  -- modeling_hypothesis
  | .s316_p07 | .s316_p08 | .s316_p09 | .s316_p10 | .s316_p12 => .modeling_hypothesis

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

end TestCoverage.S316
