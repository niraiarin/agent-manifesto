/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **conservation_invariant** (ord=4): 資源保護・保守的推定・規制準拠の絶対要件 [C1, C2, C5]
- **uncertainty_policy** (ord=3): 不確実性開示・科学的根拠提示の方針 [C3, C1]
- **data_integration_model** (ord=2): 多源データ統合・長期予測モデルの構成 [C4, C6, H1, H2]
- **modeling_hypothesis** (ord=1): 予測アーキテクチャ・統計手法の仮説 [H3, H4, H5]
-/

namespace TestCoverage.S320

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s320_p01
  | s320_p02
  | s320_p03
  | s320_p04
  | s320_p05
  | s320_p06
  | s320_p07
  | s320_p08
  | s320_p09
  | s320_p10
  | s320_p11
  | s320_p12
  | s320_p13
  | s320_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s320_p01 => []
  | .s320_p02 => [.s320_p01]
  | .s320_p03 => [.s320_p01]
  | .s320_p04 => [.s320_p02]
  | .s320_p05 => [.s320_p01, .s320_p04]
  | .s320_p06 => [.s320_p04]
  | .s320_p07 => [.s320_p05]
  | .s320_p08 => [.s320_p05, .s320_p06]
  | .s320_p09 => [.s320_p06]
  | .s320_p10 => [.s320_p04, .s320_p08]
  | .s320_p11 => [.s320_p07, .s320_p10]
  | .s320_p12 => [.s320_p08, .s320_p10]
  | .s320_p13 => [.s320_p03, .s320_p12]
  | .s320_p14 => [.s320_p06, .s320_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 資源保護・保守的推定・規制準拠の絶対要件 (ord=4) -/
  | conservation_invariant
  /-- 不確実性開示・科学的根拠提示の方針 (ord=3) -/
  | uncertainty_policy
  /-- 多源データ統合・長期予測モデルの構成 (ord=2) -/
  | data_integration_model
  /-- 予測アーキテクチャ・統計手法の仮説 (ord=1) -/
  | modeling_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .conservation_invariant => 4
  | .uncertainty_policy => 3
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
  nontrivial := ⟨.conservation_invariant, .modeling_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- conservation_invariant
  | .s320_p01 | .s320_p02 | .s320_p03 => .conservation_invariant
  -- uncertainty_policy
  | .s320_p04 | .s320_p05 => .uncertainty_policy
  -- data_integration_model
  | .s320_p06 | .s320_p07 | .s320_p08 | .s320_p09 | .s320_p14 => .data_integration_model
  -- modeling_hypothesis
  | .s320_p10 | .s320_p11 | .s320_p12 | .s320_p13 => .modeling_hypothesis

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

end TestCoverage.S320
