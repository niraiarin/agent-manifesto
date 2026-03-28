/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BeneficiaryProtection** (ord=5): 年金受給者の元本保全・最低給付保証に関する絶対不変条件 [C1]
- **RegulatoryCompliance** (ord=4): 年金法・金融商品取引法・受託者責任への法的準拠要件 [C2, C3]
- **RiskGovernance** (ord=3): VaR上限・分散投資制約・流動性バッファー維持に関するリスク統治 [C4, C5]
- **AllocationPolicy** (ord=2): 国内外株式・債券・オルタナティブへの資産配分方針 [C6, H1, H2, H3]
- **MarketHypothesis** (ord=1): 金利サイクル・株式リスクプレミアム・為替トレンドに関する市場仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S422

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s422_p01
  | s422_p02
  | s422_p03
  | s422_p04
  | s422_p05
  | s422_p06
  | s422_p07
  | s422_p08
  | s422_p09
  | s422_p10
  | s422_p11
  | s422_p12
  | s422_p13
  | s422_p14
  | s422_p15
  | s422_p16
  | s422_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s422_p01 => []
  | .s422_p02 => [.s422_p01]
  | .s422_p03 => [.s422_p01]
  | .s422_p04 => [.s422_p02, .s422_p03]
  | .s422_p05 => [.s422_p02]
  | .s422_p06 => [.s422_p03]
  | .s422_p07 => [.s422_p05, .s422_p06]
  | .s422_p08 => [.s422_p05]
  | .s422_p09 => [.s422_p06]
  | .s422_p10 => [.s422_p08, .s422_p09]
  | .s422_p11 => [.s422_p08]
  | .s422_p12 => [.s422_p09]
  | .s422_p13 => [.s422_p11]
  | .s422_p14 => [.s422_p12]
  | .s422_p15 => [.s422_p13]
  | .s422_p16 => [.s422_p14]
  | .s422_p17 => [.s422_p15, .s422_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 年金受給者の元本保全・最低給付保証に関する絶対不変条件 (ord=5) -/
  | BeneficiaryProtection
  /-- 年金法・金融商品取引法・受託者責任への法的準拠要件 (ord=4) -/
  | RegulatoryCompliance
  /-- VaR上限・分散投資制約・流動性バッファー維持に関するリスク統治 (ord=3) -/
  | RiskGovernance
  /-- 国内外株式・債券・オルタナティブへの資産配分方針 (ord=2) -/
  | AllocationPolicy
  /-- 金利サイクル・株式リスクプレミアム・為替トレンドに関する市場仮説 (ord=1) -/
  | MarketHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BeneficiaryProtection => 5
  | .RegulatoryCompliance => 4
  | .RiskGovernance => 3
  | .AllocationPolicy => 2
  | .MarketHypothesis => 1

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
  bottom := .MarketHypothesis
  nontrivial := ⟨.BeneficiaryProtection, .MarketHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BeneficiaryProtection
  | .s422_p01 => .BeneficiaryProtection
  -- RegulatoryCompliance
  | .s422_p02 | .s422_p03 | .s422_p04 => .RegulatoryCompliance
  -- RiskGovernance
  | .s422_p05 | .s422_p06 | .s422_p07 => .RiskGovernance
  -- AllocationPolicy
  | .s422_p08 | .s422_p09 | .s422_p10 => .AllocationPolicy
  -- MarketHypothesis
  | .s422_p11 | .s422_p12 | .s422_p13 | .s422_p14 | .s422_p15 | .s422_p16 | .s422_p17 => .MarketHypothesis

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

end TestCoverage.S422
