/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FoodSafetyAndAllergyInvariant** (ord=4): 食品衛生法・アレルギー対応義務・異物混入防止の絶対条件 [C1, C2, C3]
- **NutritionStandardPolicy** (ord=3): 学校給食摂取基準・栄養バランス・年齢別カロリー設計ポリシー [C4, C5]
- **ProcurementAndMenuPolicy** (ord=2): 地産地消・発注サイクル・献立作成・在庫管理の方針 [C6, H1, H2]
- **MenuOptimizationHypothesis** (ord=1): 喫食率・残食分析・嗜好データを活用した献立最適化仮説 [H3, H4, H5]
-/

namespace TestCoverage.S478

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s478_p01
  | s478_p02
  | s478_p03
  | s478_p04
  | s478_p05
  | s478_p06
  | s478_p07
  | s478_p08
  | s478_p09
  | s478_p10
  | s478_p11
  | s478_p12
  | s478_p13
  | s478_p14
  | s478_p15
  | s478_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s478_p01 => []
  | .s478_p02 => []
  | .s478_p03 => [.s478_p01, .s478_p02]
  | .s478_p04 => [.s478_p01]
  | .s478_p05 => [.s478_p02]
  | .s478_p06 => [.s478_p04, .s478_p05]
  | .s478_p07 => [.s478_p03]
  | .s478_p08 => [.s478_p05]
  | .s478_p09 => [.s478_p06, .s478_p07]
  | .s478_p10 => [.s478_p07]
  | .s478_p11 => [.s478_p08]
  | .s478_p12 => [.s478_p09, .s478_p10]
  | .s478_p13 => [.s478_p10, .s478_p11]
  | .s478_p14 => [.s478_p08, .s478_p09]
  | .s478_p15 => [.s478_p06]
  | .s478_p16 => [.s478_p02, .s478_p03]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・アレルギー対応義務・異物混入防止の絶対条件 (ord=4) -/
  | FoodSafetyAndAllergyInvariant
  /-- 学校給食摂取基準・栄養バランス・年齢別カロリー設計ポリシー (ord=3) -/
  | NutritionStandardPolicy
  /-- 地産地消・発注サイクル・献立作成・在庫管理の方針 (ord=2) -/
  | ProcurementAndMenuPolicy
  /-- 喫食率・残食分析・嗜好データを活用した献立最適化仮説 (ord=1) -/
  | MenuOptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FoodSafetyAndAllergyInvariant => 4
  | .NutritionStandardPolicy => 3
  | .ProcurementAndMenuPolicy => 2
  | .MenuOptimizationHypothesis => 1

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
  bottom := .MenuOptimizationHypothesis
  nontrivial := ⟨.FoodSafetyAndAllergyInvariant, .MenuOptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FoodSafetyAndAllergyInvariant
  | .s478_p01 | .s478_p02 | .s478_p03 | .s478_p16 => .FoodSafetyAndAllergyInvariant
  -- NutritionStandardPolicy
  | .s478_p04 | .s478_p05 | .s478_p06 | .s478_p15 => .NutritionStandardPolicy
  -- ProcurementAndMenuPolicy
  | .s478_p07 | .s478_p08 | .s478_p09 | .s478_p14 => .ProcurementAndMenuPolicy
  -- MenuOptimizationHypothesis
  | .s478_p10 | .s478_p11 | .s478_p12 | .s478_p13 => .MenuOptimizationHypothesis

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

end TestCoverage.S478
