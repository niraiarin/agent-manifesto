/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ChildSafety** (ord=4): 児童の安全・プライバシーに関する絶対制約 [C1, C2]
- **PedagogicalPrinciple** (ord=3): 教育学に基づく指導原則。研究知見で更新されうる [C3, H1]
- **CurriculumDesign** (ord=2): カリキュラム・難易度設計。学習指導要領に準拠 [C4, C5, H2]
- **AdaptiveAlgorithm** (ord=1): 適応的学習アルゴリズムの設計選択 [H3, H4, H5]
- **LearningHypothesis** (ord=0): 学習効果に関する未検証仮説 [C6, H6]
-/

namespace TestCoverage.S186

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s186_p01
  | s186_p02
  | s186_p03
  | s186_p04
  | s186_p05
  | s186_p06
  | s186_p07
  | s186_p08
  | s186_p09
  | s186_p10
  | s186_p11
  | s186_p12
  | s186_p13
  | s186_p14
  | s186_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s186_p01 => []
  | .s186_p02 => []
  | .s186_p03 => [.s186_p01]
  | .s186_p04 => [.s186_p01, .s186_p02]
  | .s186_p05 => [.s186_p03]
  | .s186_p06 => [.s186_p03, .s186_p04]
  | .s186_p07 => [.s186_p04]
  | .s186_p08 => [.s186_p05]
  | .s186_p09 => [.s186_p06]
  | .s186_p10 => [.s186_p05, .s186_p07]
  | .s186_p11 => [.s186_p06]
  | .s186_p12 => [.s186_p08]
  | .s186_p13 => [.s186_p09, .s186_p10]
  | .s186_p14 => [.s186_p11]
  | .s186_p15 => [.s186_p08, .s186_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 児童の安全・プライバシーに関する絶対制約 (ord=4) -/
  | ChildSafety
  /-- 教育学に基づく指導原則。研究知見で更新されうる (ord=3) -/
  | PedagogicalPrinciple
  /-- カリキュラム・難易度設計。学習指導要領に準拠 (ord=2) -/
  | CurriculumDesign
  /-- 適応的学習アルゴリズムの設計選択 (ord=1) -/
  | AdaptiveAlgorithm
  /-- 学習効果に関する未検証仮説 (ord=0) -/
  | LearningHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ChildSafety => 4
  | .PedagogicalPrinciple => 3
  | .CurriculumDesign => 2
  | .AdaptiveAlgorithm => 1
  | .LearningHypothesis => 0

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
  bottom := .LearningHypothesis
  nontrivial := ⟨.ChildSafety, .LearningHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ChildSafety
  | .s186_p01 | .s186_p02 => .ChildSafety
  -- PedagogicalPrinciple
  | .s186_p03 | .s186_p04 => .PedagogicalPrinciple
  -- CurriculumDesign
  | .s186_p05 | .s186_p06 | .s186_p07 => .CurriculumDesign
  -- AdaptiveAlgorithm
  | .s186_p08 | .s186_p09 | .s186_p10 | .s186_p11 => .AdaptiveAlgorithm
  -- LearningHypothesis
  | .s186_p12 | .s186_p13 | .s186_p14 | .s186_p15 => .LearningHypothesis

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

end TestCoverage.S186
