/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **privacy_invariant** (ord=4): FERPA準拠・学習データ保護の絶対要件 [C3]
- **pedagogical_policy** (ord=3): 学習設計・難易度設計・教師権限の方針 [C2, C5]
- **measurement_model** (ord=2): 習熟度計測・離脱予測の方法論 [C1, C4, H1, H2]
- **optimization_hypothesis** (ord=1): 推薦アルゴリズム・フィードバック利用の仮説 [H3, H4, H5]
-/

namespace TestCoverage.S312

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s312_p01
  | s312_p02
  | s312_p03
  | s312_p04
  | s312_p05
  | s312_p06
  | s312_p07
  | s312_p08
  | s312_p09
  | s312_p10
  | s312_p11
  | s312_p12
  | s312_p13
  | s312_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s312_p01 => []
  | .s312_p02 => [.s312_p01]
  | .s312_p03 => []
  | .s312_p04 => [.s312_p03]
  | .s312_p05 => [.s312_p01]
  | .s312_p06 => [.s312_p05]
  | .s312_p07 => [.s312_p05, .s312_p06]
  | .s312_p08 => [.s312_p07]
  | .s312_p09 => [.s312_p03, .s312_p06]
  | .s312_p10 => [.s312_p04, .s312_p09]
  | .s312_p11 => [.s312_p02, .s312_p07]
  | .s312_p12 => [.s312_p06, .s312_p09]
  | .s312_p13 => [.s312_p07]
  | .s312_p14 => [.s312_p10, .s312_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- FERPA準拠・学習データ保護の絶対要件 (ord=4) -/
  | privacy_invariant
  /-- 学習設計・難易度設計・教師権限の方針 (ord=3) -/
  | pedagogical_policy
  /-- 習熟度計測・離脱予測の方法論 (ord=2) -/
  | measurement_model
  /-- 推薦アルゴリズム・フィードバック利用の仮説 (ord=1) -/
  | optimization_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .privacy_invariant => 4
  | .pedagogical_policy => 3
  | .measurement_model => 2
  | .optimization_hypothesis => 1

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
  bottom := .optimization_hypothesis
  nontrivial := ⟨.privacy_invariant, .optimization_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- privacy_invariant
  | .s312_p01 | .s312_p02 => .privacy_invariant
  -- pedagogical_policy
  | .s312_p03 | .s312_p04 => .pedagogical_policy
  -- measurement_model
  | .s312_p05 | .s312_p06 | .s312_p07 | .s312_p08 | .s312_p13 => .measurement_model
  -- optimization_hypothesis
  | .s312_p09 | .s312_p10 | .s312_p11 | .s312_p12 | .s312_p14 => .optimization_hypothesis

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

end TestCoverage.S312
