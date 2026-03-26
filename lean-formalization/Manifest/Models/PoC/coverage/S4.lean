/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ChildProtection** (ord=5): 児童保護・プライバシー。法的義務 [C1]
- **EducationalStandard** (ord=4): 教育課程基準。文科省指導要領準拠 [C2, H1]
- **PedagogicalPrinciple** (ord=3): 教育学的原則。学習理論に基づく [C3, H2]
- **AdaptiveAlgorithm** (ord=2): 適応的学習アルゴリズムのパラメータ [H3, H4]
- **LearnerPreference** (ord=1): 学習者個人の好み・ペース設定 [C5, H5]
-/

namespace TestCoverage.S4

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s4_p01
  | s4_p02
  | s4_p03
  | s4_p04
  | s4_p05
  | s4_p06
  | s4_p07
  | s4_p08
  | s4_p09
  | s4_p10
  | s4_p11
  | s4_p12
  | s4_p13
  | s4_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s4_p01 => []
  | .s4_p02 => []
  | .s4_p03 => [.s4_p01]
  | .s4_p04 => [.s4_p02]
  | .s4_p05 => [.s4_p03]
  | .s4_p06 => [.s4_p04]
  | .s4_p07 => [.s4_p03, .s4_p04]
  | .s4_p08 => [.s4_p05]
  | .s4_p09 => [.s4_p06]
  | .s4_p10 => [.s4_p05, .s4_p07]
  | .s4_p11 => [.s4_p08]
  | .s4_p12 => [.s4_p09]
  | .s4_p13 => [.s4_p10]
  | .s4_p14 => [.s4_p11, .s4_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 児童保護・プライバシー。法的義務 (ord=5) -/
  | ChildProtection
  /-- 教育課程基準。文科省指導要領準拠 (ord=4) -/
  | EducationalStandard
  /-- 教育学的原則。学習理論に基づく (ord=3) -/
  | PedagogicalPrinciple
  /-- 適応的学習アルゴリズムのパラメータ (ord=2) -/
  | AdaptiveAlgorithm
  /-- 学習者個人の好み・ペース設定 (ord=1) -/
  | LearnerPreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ChildProtection => 5
  | .EducationalStandard => 4
  | .PedagogicalPrinciple => 3
  | .AdaptiveAlgorithm => 2
  | .LearnerPreference => 1

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
  bottom := .LearnerPreference
  nontrivial := ⟨.ChildProtection, .LearnerPreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ChildProtection
  | .s4_p01 | .s4_p02 => .ChildProtection
  -- EducationalStandard
  | .s4_p03 | .s4_p04 => .EducationalStandard
  -- PedagogicalPrinciple
  | .s4_p05 | .s4_p06 | .s4_p07 => .PedagogicalPrinciple
  -- AdaptiveAlgorithm
  | .s4_p08 | .s4_p09 | .s4_p10 => .AdaptiveAlgorithm
  -- LearnerPreference
  | .s4_p11 | .s4_p12 | .s4_p13 | .s4_p14 => .LearnerPreference

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

end TestCoverage.S4
