/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FairnessEquityAbsolute** (ord=4): 採点における公平性・無差別・バイアスゼロの絶対制約。属性による差別を排除 [C1, C2]
- **CurriculumAlignment** (ord=3): 学習指導要領・評価基準・出題意図との整合性を保証する制約 [C3, C4]
- **ScoringLogic** (ord=2): 部分点配分・正誤判定・記述評価のルーブリックに基づく採点ロジック [C5, H1, H2, H3]
- **LearnerAdaptation** (ord=1): 学習者特性・誤答パターン・進捗に基づく採点フィードバック最適化仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S416

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s416_p01
  | s416_p02
  | s416_p03
  | s416_p04
  | s416_p05
  | s416_p06
  | s416_p07
  | s416_p08
  | s416_p09
  | s416_p10
  | s416_p11
  | s416_p12
  | s416_p13
  | s416_p14
  | s416_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s416_p01 => []
  | .s416_p02 => []
  | .s416_p03 => [.s416_p01, .s416_p02]
  | .s416_p04 => [.s416_p01]
  | .s416_p05 => [.s416_p02]
  | .s416_p06 => [.s416_p03, .s416_p04, .s416_p05]
  | .s416_p07 => [.s416_p04]
  | .s416_p08 => [.s416_p05, .s416_p06]
  | .s416_p09 => [.s416_p07, .s416_p08]
  | .s416_p10 => [.s416_p07]
  | .s416_p11 => [.s416_p08]
  | .s416_p12 => [.s416_p09]
  | .s416_p13 => [.s416_p10, .s416_p11]
  | .s416_p14 => [.s416_p12, .s416_p13]
  | .s416_p15 => [.s416_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 採点における公平性・無差別・バイアスゼロの絶対制約。属性による差別を排除 (ord=4) -/
  | FairnessEquityAbsolute
  /-- 学習指導要領・評価基準・出題意図との整合性を保証する制約 (ord=3) -/
  | CurriculumAlignment
  /-- 部分点配分・正誤判定・記述評価のルーブリックに基づく採点ロジック (ord=2) -/
  | ScoringLogic
  /-- 学習者特性・誤答パターン・進捗に基づく採点フィードバック最適化仮説 (ord=1) -/
  | LearnerAdaptation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FairnessEquityAbsolute => 4
  | .CurriculumAlignment => 3
  | .ScoringLogic => 2
  | .LearnerAdaptation => 1

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
  bottom := .LearnerAdaptation
  nontrivial := ⟨.FairnessEquityAbsolute, .LearnerAdaptation, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FairnessEquityAbsolute
  | .s416_p01 | .s416_p02 | .s416_p03 => .FairnessEquityAbsolute
  -- CurriculumAlignment
  | .s416_p04 | .s416_p05 | .s416_p06 => .CurriculumAlignment
  -- ScoringLogic
  | .s416_p07 | .s416_p08 | .s416_p09 | .s416_p15 => .ScoringLogic
  -- LearnerAdaptation
  | .s416_p10 | .s416_p11 | .s416_p12 | .s416_p13 | .s416_p14 => .LearnerAdaptation

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

end TestCoverage.S416
