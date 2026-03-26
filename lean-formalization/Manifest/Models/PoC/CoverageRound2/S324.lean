/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **fairness_invariant** (ord=4): 公正・無差別な査定に関する絶対不変条件 [C2, C3, C4]
- **regulatory_compliance** (ord=3): 保険業法・金融庁・個人情報保護法への適合 [C1, C6]
- **operational_policy** (ord=2): 査定プロセス・不正検出・人間審査ゲート [C3, C5, H1, H3, H4]
- **ml_model** (ord=1): 公平性制約付き学習・説明可能AI・フェデレーテッドラーニングの仮説 [H2, H5]
-/

namespace TestCoverage.S324

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s324_p01
  | s324_p02
  | s324_p03
  | s324_p04
  | s324_p05
  | s324_p06
  | s324_p07
  | s324_p08
  | s324_p09
  | s324_p10
  | s324_p11
  | s324_p12
  | s324_p13
  | s324_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s324_p01 => []
  | .s324_p02 => []
  | .s324_p03 => [.s324_p01, .s324_p02]
  | .s324_p04 => [.s324_p02]
  | .s324_p05 => [.s324_p04]
  | .s324_p06 => [.s324_p04, .s324_p05]
  | .s324_p07 => [.s324_p03]
  | .s324_p08 => [.s324_p02]
  | .s324_p09 => [.s324_p06]
  | .s324_p10 => [.s324_p07, .s324_p08]
  | .s324_p11 => [.s324_p09]
  | .s324_p12 => [.s324_p01, .s324_p10]
  | .s324_p13 => [.s324_p05]
  | .s324_p14 => [.s324_p08, .s324_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 公正・無差別な査定に関する絶対不変条件 (ord=4) -/
  | fairness_invariant
  /-- 保険業法・金融庁・個人情報保護法への適合 (ord=3) -/
  | regulatory_compliance
  /-- 査定プロセス・不正検出・人間審査ゲート (ord=2) -/
  | operational_policy
  /-- 公平性制約付き学習・説明可能AI・フェデレーテッドラーニングの仮説 (ord=1) -/
  | ml_model
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .fairness_invariant => 4
  | .regulatory_compliance => 3
  | .operational_policy => 2
  | .ml_model => 1

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
  bottom := .ml_model
  nontrivial := ⟨.fairness_invariant, .ml_model, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- fairness_invariant
  | .s324_p01 | .s324_p02 | .s324_p03 => .fairness_invariant
  -- regulatory_compliance
  | .s324_p04 | .s324_p05 | .s324_p06 => .regulatory_compliance
  -- operational_policy
  | .s324_p07 | .s324_p08 | .s324_p09 | .s324_p10 | .s324_p11 => .operational_policy
  -- ml_model
  | .s324_p12 | .s324_p13 | .s324_p14 => .ml_model

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

end TestCoverage.S324
