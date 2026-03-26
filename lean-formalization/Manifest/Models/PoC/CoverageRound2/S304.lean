/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ComplianceInvariant** (ord=4): マネーロンダリング防止法・金融規制への絶対適合要件 [C1, C2]
- **DetectionPolicy** (ord=3): 不正検知の閾値・エスカレーション・調査起動方針 [C3, C4, H1]
- **RiskScoringModel** (ord=2): リスクスコア算出・取引パターン分類モデル [C5, H2, H3, H4]
- **BehaviorHypothesis** (ord=1): 顧客行動変化・新手口推定に関する仮説 [C6, H5, H6, H7]
-/

namespace TestCoverage.S304

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s304_p01
  | s304_p02
  | s304_p03
  | s304_p04
  | s304_p05
  | s304_p06
  | s304_p07
  | s304_p08
  | s304_p09
  | s304_p10
  | s304_p11
  | s304_p12
  | s304_p13
  | s304_p14
  | s304_p15
  | s304_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s304_p01 => []
  | .s304_p02 => []
  | .s304_p03 => [.s304_p01]
  | .s304_p04 => [.s304_p01]
  | .s304_p05 => [.s304_p02]
  | .s304_p06 => [.s304_p03, .s304_p04]
  | .s304_p07 => [.s304_p04]
  | .s304_p08 => [.s304_p05]
  | .s304_p09 => [.s304_p06]
  | .s304_p10 => [.s304_p07, .s304_p08]
  | .s304_p11 => [.s304_p07]
  | .s304_p12 => [.s304_p08, .s304_p09]
  | .s304_p13 => [.s304_p10]
  | .s304_p14 => [.s304_p11]
  | .s304_p15 => [.s304_p12, .s304_p13]
  | .s304_p16 => [.s304_p14, .s304_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- マネーロンダリング防止法・金融規制への絶対適合要件 (ord=4) -/
  | ComplianceInvariant
  /-- 不正検知の閾値・エスカレーション・調査起動方針 (ord=3) -/
  | DetectionPolicy
  /-- リスクスコア算出・取引パターン分類モデル (ord=2) -/
  | RiskScoringModel
  /-- 顧客行動変化・新手口推定に関する仮説 (ord=1) -/
  | BehaviorHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ComplianceInvariant => 4
  | .DetectionPolicy => 3
  | .RiskScoringModel => 2
  | .BehaviorHypothesis => 1

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
  bottom := .BehaviorHypothesis
  nontrivial := ⟨.ComplianceInvariant, .BehaviorHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ComplianceInvariant
  | .s304_p01 | .s304_p02 | .s304_p03 => .ComplianceInvariant
  -- DetectionPolicy
  | .s304_p04 | .s304_p05 | .s304_p06 => .DetectionPolicy
  -- RiskScoringModel
  | .s304_p07 | .s304_p08 | .s304_p09 | .s304_p10 => .RiskScoringModel
  -- BehaviorHypothesis
  | .s304_p11 | .s304_p12 | .s304_p13 | .s304_p14 | .s304_p15 | .s304_p16 => .BehaviorHypothesis

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

end TestCoverage.S304
