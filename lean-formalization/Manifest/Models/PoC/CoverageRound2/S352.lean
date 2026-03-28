/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **FairLendingInvariant** (ord=5): 差別禁止・公正貸付法への絶対準拠。属性による不当差別の禁止 [C1, C2]
- **RegulatoryCompliance** (ord=4): 金融庁ガイドライン・個人情報保護法・AI公正利用規制への適合 [C3, C4]
- **CreditPolicy** (ord=3): 融資基準・担保評価・信用スコア閾値の業務方針 [C5, C6, H1]
- **RiskAssessment** (ord=2): デフォルト確率推定・金利算定・LTV評価に関するリスクモデル [H2, H3, H4]
- **MarketHypothesis** (ord=1): 不動産市況・金利動向・経済指標に関する予測仮説 [H5, H6, H7]
-/

namespace TestCoverage.S352

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s352_p01
  | s352_p02
  | s352_p03
  | s352_p04
  | s352_p05
  | s352_p06
  | s352_p07
  | s352_p08
  | s352_p09
  | s352_p10
  | s352_p11
  | s352_p12
  | s352_p13
  | s352_p14
  | s352_p15
  | s352_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s352_p01 => []
  | .s352_p02 => []
  | .s352_p03 => [.s352_p01]
  | .s352_p04 => [.s352_p01]
  | .s352_p05 => [.s352_p02]
  | .s352_p06 => [.s352_p04]
  | .s352_p07 => [.s352_p05]
  | .s352_p08 => [.s352_p03, .s352_p04]
  | .s352_p09 => [.s352_p06]
  | .s352_p10 => [.s352_p07]
  | .s352_p11 => [.s352_p08]
  | .s352_p12 => [.s352_p09]
  | .s352_p13 => [.s352_p09]
  | .s352_p14 => [.s352_p10]
  | .s352_p15 => [.s352_p11, .s352_p12]
  | .s352_p16 => [.s352_p13, .s352_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 差別禁止・公正貸付法への絶対準拠。属性による不当差別の禁止 (ord=5) -/
  | FairLendingInvariant
  /-- 金融庁ガイドライン・個人情報保護法・AI公正利用規制への適合 (ord=4) -/
  | RegulatoryCompliance
  /-- 融資基準・担保評価・信用スコア閾値の業務方針 (ord=3) -/
  | CreditPolicy
  /-- デフォルト確率推定・金利算定・LTV評価に関するリスクモデル (ord=2) -/
  | RiskAssessment
  /-- 不動産市況・金利動向・経済指標に関する予測仮説 (ord=1) -/
  | MarketHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .FairLendingInvariant => 5
  | .RegulatoryCompliance => 4
  | .CreditPolicy => 3
  | .RiskAssessment => 2
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
  nontrivial := ⟨.FairLendingInvariant, .MarketHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- FairLendingInvariant
  | .s352_p01 | .s352_p02 | .s352_p03 => .FairLendingInvariant
  -- RegulatoryCompliance
  | .s352_p04 | .s352_p05 => .RegulatoryCompliance
  -- CreditPolicy
  | .s352_p06 | .s352_p07 | .s352_p08 => .CreditPolicy
  -- RiskAssessment
  | .s352_p09 | .s352_p10 | .s352_p11 | .s352_p12 => .RiskAssessment
  -- MarketHypothesis
  | .s352_p13 | .s352_p14 | .s352_p15 | .s352_p16 => .MarketHypothesis

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

end TestCoverage.S352
