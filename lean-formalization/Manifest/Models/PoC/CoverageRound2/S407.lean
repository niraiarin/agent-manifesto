/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalSafetyInvariant** (ord=4): CO2回収プロセスの環境安全・二次汚染防止の不変制約 [C1, C2]
- **RegulatoryEmissionsCompliance** (ord=3): 排出規制・カーボンクレジット制度への準拠。環境法令に基づく義務 [C3, H1]
- **OperationalEfficiencyPolicy** (ord=2): 回収プロセス効率・エネルギー消費ポリシー。運用コスト最適化規則 [C4, H2, H3]
- **ProcessOptimizationHypothesis** (ord=1): 触媒性能・温度・圧力最適化の仮説。実験データで継続的に検証 [H4, H5, H6]
-/

namespace TestCoverage.S407

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s407_p01
  | s407_p02
  | s407_p03
  | s407_p04
  | s407_p05
  | s407_p06
  | s407_p07
  | s407_p08
  | s407_p09
  | s407_p10
  | s407_p11
  | s407_p12
  | s407_p13
  | s407_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s407_p01 => []
  | .s407_p02 => []
  | .s407_p03 => [.s407_p01, .s407_p02]
  | .s407_p04 => [.s407_p01]
  | .s407_p05 => [.s407_p02]
  | .s407_p06 => [.s407_p03]
  | .s407_p07 => [.s407_p04]
  | .s407_p08 => [.s407_p05]
  | .s407_p09 => [.s407_p06]
  | .s407_p10 => [.s407_p07, .s407_p08]
  | .s407_p11 => [.s407_p07]
  | .s407_p12 => [.s407_p08]
  | .s407_p13 => [.s407_p09]
  | .s407_p14 => [.s407_p10, .s407_p11, .s407_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- CO2回収プロセスの環境安全・二次汚染防止の不変制約 (ord=4) -/
  | EnvironmentalSafetyInvariant
  /-- 排出規制・カーボンクレジット制度への準拠。環境法令に基づく義務 (ord=3) -/
  | RegulatoryEmissionsCompliance
  /-- 回収プロセス効率・エネルギー消費ポリシー。運用コスト最適化規則 (ord=2) -/
  | OperationalEfficiencyPolicy
  /-- 触媒性能・温度・圧力最適化の仮説。実験データで継続的に検証 (ord=1) -/
  | ProcessOptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalSafetyInvariant => 4
  | .RegulatoryEmissionsCompliance => 3
  | .OperationalEfficiencyPolicy => 2
  | .ProcessOptimizationHypothesis => 1

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
  bottom := .ProcessOptimizationHypothesis
  nontrivial := ⟨.EnvironmentalSafetyInvariant, .ProcessOptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalSafetyInvariant
  | .s407_p01 | .s407_p02 | .s407_p03 => .EnvironmentalSafetyInvariant
  -- RegulatoryEmissionsCompliance
  | .s407_p04 | .s407_p05 | .s407_p06 => .RegulatoryEmissionsCompliance
  -- OperationalEfficiencyPolicy
  | .s407_p07 | .s407_p08 | .s407_p09 | .s407_p10 => .OperationalEfficiencyPolicy
  -- ProcessOptimizationHypothesis
  | .s407_p11 | .s407_p12 | .s407_p13 | .s407_p14 => .ProcessOptimizationHypothesis

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

end TestCoverage.S407
