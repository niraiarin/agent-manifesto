/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AudioFundamental** (ord=2): 音響工学の物理的制約と品質基準 [C1, C2, C3]
- **SeparationArchitecture** (ord=1): 音源分離アーキテクチャの設計選択 [C4, C5, H1, H2, H3]
- **TrainingStrategy** (ord=0): 学習戦略の仮説。実験で検証が必要 [H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s128_p01
  | s128_p02
  | s128_p03
  | s128_p04
  | s128_p05
  | s128_p06
  | s128_p07
  | s128_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s128_p01 => []
  | .s128_p02 => []
  | .s128_p03 => []
  | .s128_p04 => [.s128_p01]
  | .s128_p05 => [.s128_p02, .s128_p03]
  | .s128_p06 => [.s128_p01, .s128_p02]
  | .s128_p07 => [.s128_p04]
  | .s128_p08 => [.s128_p05, .s128_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 音響工学の物理的制約と品質基準 (ord=2) -/
  | AudioFundamental
  /-- 音源分離アーキテクチャの設計選択 (ord=1) -/
  | SeparationArchitecture
  /-- 学習戦略の仮説。実験で検証が必要 (ord=0) -/
  | TrainingStrategy
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AudioFundamental => 2
  | .SeparationArchitecture => 1
  | .TrainingStrategy => 0

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
  bottom := .TrainingStrategy
  nontrivial := ⟨.AudioFundamental, .TrainingStrategy, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AudioFundamental
  | .s128_p01 | .s128_p02 | .s128_p03 => .AudioFundamental
  -- SeparationArchitecture
  | .s128_p04 | .s128_p05 | .s128_p06 => .SeparationArchitecture
  -- TrainingStrategy
  | .s128_p07 | .s128_p08 => .TrainingStrategy

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

end Manifest.Models
