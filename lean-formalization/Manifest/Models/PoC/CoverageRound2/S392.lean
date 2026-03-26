/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **RegulatoryCompliance** (ord=4): 金融庁ガイドライン・貸金業法・個人情報保護法への完全適合（絶対制約） [C1, C2]
- **CreditRiskInvariant** (ord=3): 信用リスク評価に関する基本原則（担保・保証人・財務指標の必須確認） [C3, C4]
- **FairnessPolicy** (ord=2): 審査における差別禁止・公平性確保の方針（性別・地域・業種による不当排除禁止） [C5, C6]
- **ScoringModelHypothesis** (ord=1): 機械学習スコアリングモデルの精度・解釈可能性に関する仮説 [H1, H2, H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S392

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s392_p01
  | s392_p02
  | s392_p03
  | s392_p04
  | s392_p05
  | s392_p06
  | s392_p07
  | s392_p08
  | s392_p09
  | s392_p10
  | s392_p11
  | s392_p12
  | s392_p13
  | s392_p14
  | s392_p15
  | s392_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s392_p01 => []
  | .s392_p02 => []
  | .s392_p03 => [.s392_p01, .s392_p02]
  | .s392_p04 => [.s392_p01]
  | .s392_p05 => [.s392_p02]
  | .s392_p06 => [.s392_p04, .s392_p05]
  | .s392_p07 => [.s392_p03]
  | .s392_p08 => [.s392_p06]
  | .s392_p09 => [.s392_p07, .s392_p08]
  | .s392_p10 => [.s392_p04]
  | .s392_p11 => [.s392_p07]
  | .s392_p12 => [.s392_p09]
  | .s392_p13 => [.s392_p10]
  | .s392_p14 => [.s392_p11]
  | .s392_p15 => [.s392_p12]
  | .s392_p16 => [.s392_p13, .s392_p14, .s392_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 金融庁ガイドライン・貸金業法・個人情報保護法への完全適合（絶対制約） (ord=4) -/
  | RegulatoryCompliance
  /-- 信用リスク評価に関する基本原則（担保・保証人・財務指標の必須確認） (ord=3) -/
  | CreditRiskInvariant
  /-- 審査における差別禁止・公平性確保の方針（性別・地域・業種による不当排除禁止） (ord=2) -/
  | FairnessPolicy
  /-- 機械学習スコアリングモデルの精度・解釈可能性に関する仮説 (ord=1) -/
  | ScoringModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .RegulatoryCompliance => 4
  | .CreditRiskInvariant => 3
  | .FairnessPolicy => 2
  | .ScoringModelHypothesis => 1

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
  bottom := .ScoringModelHypothesis
  nontrivial := ⟨.RegulatoryCompliance, .ScoringModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- RegulatoryCompliance
  | .s392_p01 | .s392_p02 | .s392_p03 => .RegulatoryCompliance
  -- CreditRiskInvariant
  | .s392_p04 | .s392_p05 | .s392_p06 => .CreditRiskInvariant
  -- FairnessPolicy
  | .s392_p07 | .s392_p08 | .s392_p09 => .FairnessPolicy
  -- ScoringModelHypothesis
  | .s392_p10 | .s392_p11 | .s392_p12 | .s392_p13 | .s392_p14 | .s392_p15 | .s392_p16 => .ScoringModelHypothesis

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

end TestCoverage.S392
