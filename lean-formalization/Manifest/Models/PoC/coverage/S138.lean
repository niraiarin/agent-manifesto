/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DisasterPreparedness** (ord=4): 災害対策基本法に基づく備蓄義務。法的要請 [C1, C2]
- **InventoryPolicy** (ord=3): 備蓄品目・数量の管理方針。自治体判断で変更可能 [C3, C4, H1]
- **OptimizationDesign** (ord=2): 在庫最適化の設計選択。コスト効率で判断 [C5, H2]
- **DemandForecast** (ord=1): 需要予測の仮説。過去の災害データで検証 [H3, H4]
-/

namespace TestCoverage.S138

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s138_p01
  | s138_p02
  | s138_p03
  | s138_p04
  | s138_p05
  | s138_p06
  | s138_p07
  | s138_p08
  | s138_p09
  | s138_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s138_p01 => []
  | .s138_p02 => []
  | .s138_p03 => [.s138_p01]
  | .s138_p04 => [.s138_p01, .s138_p02]
  | .s138_p05 => [.s138_p02]
  | .s138_p06 => [.s138_p03]
  | .s138_p07 => [.s138_p04]
  | .s138_p08 => [.s138_p06]
  | .s138_p09 => [.s138_p05, .s138_p07]
  | .s138_p10 => [.s138_p06, .s138_p07]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 災害対策基本法に基づく備蓄義務。法的要請 (ord=4) -/
  | DisasterPreparedness
  /-- 備蓄品目・数量の管理方針。自治体判断で変更可能 (ord=3) -/
  | InventoryPolicy
  /-- 在庫最適化の設計選択。コスト効率で判断 (ord=2) -/
  | OptimizationDesign
  /-- 需要予測の仮説。過去の災害データで検証 (ord=1) -/
  | DemandForecast
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DisasterPreparedness => 4
  | .InventoryPolicy => 3
  | .OptimizationDesign => 2
  | .DemandForecast => 1

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
  bottom := .DemandForecast
  nontrivial := ⟨.DisasterPreparedness, .DemandForecast, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DisasterPreparedness
  | .s138_p01 | .s138_p02 => .DisasterPreparedness
  -- InventoryPolicy
  | .s138_p03 | .s138_p04 | .s138_p05 => .InventoryPolicy
  -- OptimizationDesign
  | .s138_p06 | .s138_p07 => .OptimizationDesign
  -- DemandForecast
  | .s138_p08 | .s138_p09 | .s138_p10 => .DemandForecast

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

end TestCoverage.S138
