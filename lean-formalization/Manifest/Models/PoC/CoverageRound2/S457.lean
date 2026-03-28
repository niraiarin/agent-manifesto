/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WasteRegulationInvariant** (ord=4): 廃棄物処理法・地方自治体条例に基づく収集義務・不法投棄防止の絶対制約 [C1, C2]
- **PublicHealthSafetyPolicy** (ord=3): 衛生管理・有害物質分別・医療廃棄物取扱いの保健行政方針 [C3, H1]
- **RouteOptimizationRule** (ord=2): 車両積載効率・燃費・収集頻度の最適化ルール。交通規制・収集時間帯制約を考慮 [C4, H2, H3]
- **DemandForecastHypothesis** (ord=1): 排出量季節変動・イベント影響・人口増減による需要予測仮説 [C5, H4, H5]
-/

namespace TestCoverage.S457

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s457_p01
  | s457_p02
  | s457_p03
  | s457_p04
  | s457_p05
  | s457_p06
  | s457_p07
  | s457_p08
  | s457_p09
  | s457_p10
  | s457_p11
  | s457_p12
  | s457_p13
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s457_p01 => []
  | .s457_p02 => []
  | .s457_p03 => [.s457_p01]
  | .s457_p04 => [.s457_p02]
  | .s457_p05 => [.s457_p03, .s457_p04]
  | .s457_p06 => [.s457_p03]
  | .s457_p07 => [.s457_p04, .s457_p05]
  | .s457_p08 => [.s457_p06, .s457_p07]
  | .s457_p09 => [.s457_p06]
  | .s457_p10 => [.s457_p07, .s457_p08]
  | .s457_p11 => [.s457_p09]
  | .s457_p12 => [.s457_p10, .s457_p11]
  | .s457_p13 => [.s457_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 廃棄物処理法・地方自治体条例に基づく収集義務・不法投棄防止の絶対制約 (ord=4) -/
  | WasteRegulationInvariant
  /-- 衛生管理・有害物質分別・医療廃棄物取扱いの保健行政方針 (ord=3) -/
  | PublicHealthSafetyPolicy
  /-- 車両積載効率・燃費・収集頻度の最適化ルール。交通規制・収集時間帯制約を考慮 (ord=2) -/
  | RouteOptimizationRule
  /-- 排出量季節変動・イベント影響・人口増減による需要予測仮説 (ord=1) -/
  | DemandForecastHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WasteRegulationInvariant => 4
  | .PublicHealthSafetyPolicy => 3
  | .RouteOptimizationRule => 2
  | .DemandForecastHypothesis => 1

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
  bottom := .DemandForecastHypothesis
  nontrivial := ⟨.WasteRegulationInvariant, .DemandForecastHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WasteRegulationInvariant
  | .s457_p01 | .s457_p02 => .WasteRegulationInvariant
  -- PublicHealthSafetyPolicy
  | .s457_p03 | .s457_p04 | .s457_p05 => .PublicHealthSafetyPolicy
  -- RouteOptimizationRule
  | .s457_p06 | .s457_p07 | .s457_p08 => .RouteOptimizationRule
  -- DemandForecastHypothesis
  | .s457_p09 | .s457_p10 | .s457_p11 | .s457_p12 | .s457_p13 => .DemandForecastHypothesis

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

end TestCoverage.S457
