/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LearnerWelfare** (ord=4): 学習者の心理的安全・過負荷防止に関する絶対不変条件 [C1]
- **EducationalPolicy** (ord=3): 学習指導要領・単位認定・アクセシビリティ確保の教育方針 [C2, C3]
- **PersonalizationPolicy** (ord=2): 個別学習経路・難易度調整・フィードバック頻度の方針 [C4, C5, H1, H2]
- **LearningHypothesis** (ord=1): 習熟速度・記憶定着・動機維持に関するML推論仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S346

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s346_p01
  | s346_p02
  | s346_p03
  | s346_p04
  | s346_p05
  | s346_p06
  | s346_p07
  | s346_p08
  | s346_p09
  | s346_p10
  | s346_p11
  | s346_p12
  | s346_p13
  | s346_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s346_p01 => []
  | .s346_p02 => [.s346_p01]
  | .s346_p03 => [.s346_p01]
  | .s346_p04 => [.s346_p02]
  | .s346_p05 => [.s346_p03]
  | .s346_p06 => [.s346_p04, .s346_p05]
  | .s346_p07 => [.s346_p04]
  | .s346_p08 => [.s346_p05]
  | .s346_p09 => [.s346_p06, .s346_p07]
  | .s346_p10 => [.s346_p08]
  | .s346_p11 => [.s346_p09]
  | .s346_p12 => [.s346_p10]
  | .s346_p13 => [.s346_p11, .s346_p12]
  | .s346_p14 => [.s346_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 学習者の心理的安全・過負荷防止に関する絶対不変条件 (ord=4) -/
  | LearnerWelfare
  /-- 学習指導要領・単位認定・アクセシビリティ確保の教育方針 (ord=3) -/
  | EducationalPolicy
  /-- 個別学習経路・難易度調整・フィードバック頻度の方針 (ord=2) -/
  | PersonalizationPolicy
  /-- 習熟速度・記憶定着・動機維持に関するML推論仮説 (ord=1) -/
  | LearningHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LearnerWelfare => 4
  | .EducationalPolicy => 3
  | .PersonalizationPolicy => 2
  | .LearningHypothesis => 1

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
  nontrivial := ⟨.LearnerWelfare, .LearningHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LearnerWelfare
  | .s346_p01 => .LearnerWelfare
  -- EducationalPolicy
  | .s346_p02 | .s346_p03 => .EducationalPolicy
  -- PersonalizationPolicy
  | .s346_p04 | .s346_p05 | .s346_p06 => .PersonalizationPolicy
  -- LearningHypothesis
  | .s346_p07 | .s346_p08 | .s346_p09 | .s346_p10 | .s346_p11 | .s346_p12 | .s346_p13 | .s346_p14 => .LearningHypothesis

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

end TestCoverage.S346
