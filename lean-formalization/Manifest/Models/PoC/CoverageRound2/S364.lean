/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SupplyResilience** (ord=5): 供給途絶リスクへの耐性・事業継続性の最上位不変条件 [C1, C2]
- **ContractualCompliance** (ord=4): 取引先契約・納期義務・品質基準への遵守要件 [C3, C4]
- **InventoryPolicy** (ord=3): 安全在庫水準・発注点・リードタイム管理方針 [C5, C6, H1]
- **DemandForecastModel** (ord=2): 需要予測・季節性調整・突発需要対応モデル [C7, H2, H3, H4]
- **NetworkOptimizationHypothesis** (ord=1): 調達ルート・物流ネットワーク最適化の推論仮説 [H5, H6]
-/

namespace TestCoverage.S364

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s364_p01
  | s364_p02
  | s364_p03
  | s364_p04
  | s364_p05
  | s364_p06
  | s364_p07
  | s364_p08
  | s364_p09
  | s364_p10
  | s364_p11
  | s364_p12
  | s364_p13
  | s364_p14
  | s364_p15
  | s364_p16
  | s364_p17
  | s364_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s364_p01 => []
  | .s364_p02 => []
  | .s364_p03 => [.s364_p01, .s364_p02]
  | .s364_p04 => [.s364_p01]
  | .s364_p05 => [.s364_p02]
  | .s364_p06 => [.s364_p04, .s364_p05]
  | .s364_p07 => [.s364_p04]
  | .s364_p08 => [.s364_p05]
  | .s364_p09 => [.s364_p06, .s364_p07]
  | .s364_p10 => [.s364_p07]
  | .s364_p11 => [.s364_p08]
  | .s364_p12 => [.s364_p09]
  | .s364_p13 => [.s364_p10, .s364_p11]
  | .s364_p14 => [.s364_p10]
  | .s364_p15 => [.s364_p12]
  | .s364_p16 => [.s364_p13, .s364_p14]
  | .s364_p17 => [.s364_p15, .s364_p16]
  | .s364_p18 => [.s364_p03, .s364_p17]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 供給途絶リスクへの耐性・事業継続性の最上位不変条件 (ord=5) -/
  | SupplyResilience
  /-- 取引先契約・納期義務・品質基準への遵守要件 (ord=4) -/
  | ContractualCompliance
  /-- 安全在庫水準・発注点・リードタイム管理方針 (ord=3) -/
  | InventoryPolicy
  /-- 需要予測・季節性調整・突発需要対応モデル (ord=2) -/
  | DemandForecastModel
  /-- 調達ルート・物流ネットワーク最適化の推論仮説 (ord=1) -/
  | NetworkOptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SupplyResilience => 5
  | .ContractualCompliance => 4
  | .InventoryPolicy => 3
  | .DemandForecastModel => 2
  | .NetworkOptimizationHypothesis => 1

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
  bottom := .NetworkOptimizationHypothesis
  nontrivial := ⟨.SupplyResilience, .NetworkOptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SupplyResilience
  | .s364_p01 | .s364_p02 | .s364_p03 => .SupplyResilience
  -- ContractualCompliance
  | .s364_p04 | .s364_p05 | .s364_p06 => .ContractualCompliance
  -- InventoryPolicy
  | .s364_p07 | .s364_p08 | .s364_p09 => .InventoryPolicy
  -- DemandForecastModel
  | .s364_p10 | .s364_p11 | .s364_p12 | .s364_p13 => .DemandForecastModel
  -- NetworkOptimizationHypothesis
  | .s364_p14 | .s364_p15 | .s364_p16 | .s364_p17 | .s364_p18 => .NetworkOptimizationHypothesis

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

end TestCoverage.S364
