/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DataInfrastructure** (ord=3): 気象観測・花粉計測の物理的基盤。変更不可 [C1, C2]
- **PredictionModel** (ord=2): 予測アルゴリズムとパラメータ設計。データに基づき改善可能 [C3, H1, H2]
- **DeliveryFormat** (ord=1): 予測結果の配信方式と表示形式 [C4, H3, H4]
-/

namespace TestCoverage.S152

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s152_p01
  | s152_p02
  | s152_p03
  | s152_p04
  | s152_p05
  | s152_p06
  | s152_p07
  | s152_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s152_p01 => []
  | .s152_p02 => []
  | .s152_p03 => [.s152_p01]
  | .s152_p04 => [.s152_p01, .s152_p02]
  | .s152_p05 => [.s152_p02]
  | .s152_p06 => [.s152_p03]
  | .s152_p07 => [.s152_p04]
  | .s152_p08 => [.s152_p05, .s152_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 気象観測・花粉計測の物理的基盤。変更不可 (ord=3) -/
  | DataInfrastructure
  /-- 予測アルゴリズムとパラメータ設計。データに基づき改善可能 (ord=2) -/
  | PredictionModel
  /-- 予測結果の配信方式と表示形式 (ord=1) -/
  | DeliveryFormat
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DataInfrastructure => 3
  | .PredictionModel => 2
  | .DeliveryFormat => 1

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
  bottom := .DeliveryFormat
  nontrivial := ⟨.DataInfrastructure, .DeliveryFormat, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DataInfrastructure
  | .s152_p01 | .s152_p02 => .DataInfrastructure
  -- PredictionModel
  | .s152_p03 | .s152_p04 | .s152_p05 => .PredictionModel
  -- DeliveryFormat
  | .s152_p06 | .s152_p07 | .s152_p08 => .DeliveryFormat

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

end TestCoverage.S152
