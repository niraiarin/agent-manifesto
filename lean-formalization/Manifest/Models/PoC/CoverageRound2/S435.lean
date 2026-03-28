/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FoodSafetyInvariant** (ord=3): 食品衛生法・HACCP・細菌増殖限界の絶対制約 [C1, C2]
- **StorageManagementPolicy** (ord=2): 温度帯管理・湿度制御・先入先出原則の方針 [C3, H1]
- **FreshnessDecayHypothesis** (ord=1): 品目別鮮度劣化速度・廃棄タイミングの予測仮説 [C4, H2, H3]
-/

namespace TestCoverage.S435

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s435_p01
  | s435_p02
  | s435_p03
  | s435_p04
  | s435_p05
  | s435_p06
  | s435_p07
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s435_p01 => []
  | .s435_p02 => []
  | .s435_p03 => [.s435_p01]
  | .s435_p04 => [.s435_p02, .s435_p03]
  | .s435_p05 => [.s435_p03]
  | .s435_p06 => [.s435_p04]
  | .s435_p07 => [.s435_p05, .s435_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・HACCP・細菌増殖限界の絶対制約 (ord=3) -/
  | FoodSafetyInvariant
  /-- 温度帯管理・湿度制御・先入先出原則の方針 (ord=2) -/
  | StorageManagementPolicy
  /-- 品目別鮮度劣化速度・廃棄タイミングの予測仮説 (ord=1) -/
  | FreshnessDecayHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FoodSafetyInvariant => 3
  | .StorageManagementPolicy => 2
  | .FreshnessDecayHypothesis => 1

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
  bottom := .FreshnessDecayHypothesis
  nontrivial := ⟨.FoodSafetyInvariant, .FreshnessDecayHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FoodSafetyInvariant
  | .s435_p01 | .s435_p02 => .FoodSafetyInvariant
  -- StorageManagementPolicy
  | .s435_p03 | .s435_p04 => .StorageManagementPolicy
  -- FreshnessDecayHypothesis
  | .s435_p05 | .s435_p06 | .s435_p07 => .FreshnessDecayHypothesis

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

end TestCoverage.S435
