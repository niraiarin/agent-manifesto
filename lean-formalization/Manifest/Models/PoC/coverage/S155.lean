/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalRegulation** (ord=5): 排水基準値（BOD・COD・窒素・リン等）。法令遵守義務 [C1]
- **ProcessConstraint** (ord=4): 処理施設の物理的・生物学的制約 [C2, C3]
- **ControlStrategy** (ord=3): 曝気・薬注・汚泥管理の制御戦略 [C4, H1, H2]
- **EnergyOptimization** (ord=2): 電力消費・薬品コストの最適化 [H3, H4]
- **OperationalAdjustment** (ord=1): 季節・流入変動に応じた微調整 [C5, H5, H6]
-/

namespace TestCoverage.S155

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s155_p01
  | s155_p02
  | s155_p03
  | s155_p04
  | s155_p05
  | s155_p06
  | s155_p07
  | s155_p08
  | s155_p09
  | s155_p10
  | s155_p11
  | s155_p12
  | s155_p13
  | s155_p14
  | s155_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s155_p01 => []
  | .s155_p02 => []
  | .s155_p03 => [.s155_p01]
  | .s155_p04 => [.s155_p01]
  | .s155_p05 => [.s155_p01, .s155_p02]
  | .s155_p06 => [.s155_p03]
  | .s155_p07 => [.s155_p04]
  | .s155_p08 => [.s155_p03, .s155_p05]
  | .s155_p09 => [.s155_p06]
  | .s155_p10 => [.s155_p07, .s155_p08]
  | .s155_p11 => [.s155_p06]
  | .s155_p12 => [.s155_p09]
  | .s155_p13 => [.s155_p10]
  | .s155_p14 => [.s155_p11]
  | .s155_p15 => [.s155_p12, .s155_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 排水基準値（BOD・COD・窒素・リン等）。法令遵守義務 (ord=5) -/
  | EnvironmentalRegulation
  /-- 処理施設の物理的・生物学的制約 (ord=4) -/
  | ProcessConstraint
  /-- 曝気・薬注・汚泥管理の制御戦略 (ord=3) -/
  | ControlStrategy
  /-- 電力消費・薬品コストの最適化 (ord=2) -/
  | EnergyOptimization
  /-- 季節・流入変動に応じた微調整 (ord=1) -/
  | OperationalAdjustment
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalRegulation => 5
  | .ProcessConstraint => 4
  | .ControlStrategy => 3
  | .EnergyOptimization => 2
  | .OperationalAdjustment => 1

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
  bottom := .OperationalAdjustment
  nontrivial := ⟨.EnvironmentalRegulation, .OperationalAdjustment, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalRegulation
  | .s155_p01 | .s155_p02 => .EnvironmentalRegulation
  -- ProcessConstraint
  | .s155_p03 | .s155_p04 | .s155_p05 => .ProcessConstraint
  -- ControlStrategy
  | .s155_p06 | .s155_p07 | .s155_p08 => .ControlStrategy
  -- EnergyOptimization
  | .s155_p09 | .s155_p10 | .s155_p11 => .EnergyOptimization
  -- OperationalAdjustment
  | .s155_p12 | .s155_p13 | .s155_p14 | .s155_p15 => .OperationalAdjustment

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

end TestCoverage.S155
