/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalAccuracyInvariant** (ord=4): 法令情報の誤りが業務違反を招くことを防ぐ絶対正確性要件 [C1, C2]
- **RegulatoryUpdatePolicy** (ord=3): 法改正・ガイドライン更新の即時反映・バージョン管理方針 [C3, C4]
- **LearnerAdaptationModel** (ord=2): 受講者の理解度・職種・リスク領域に応じた研修カスタマイズ [C5, C6, H1, H2]
- **KnowledgeRetentionHypothesis** (ord=1): 繰り返し学習・事例演習・定期テストによる定着率向上仮説 [H3, H4, H5]
-/

namespace TestCoverage.S488

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s488_p01
  | s488_p02
  | s488_p03
  | s488_p04
  | s488_p05
  | s488_p06
  | s488_p07
  | s488_p08
  | s488_p09
  | s488_p10
  | s488_p11
  | s488_p12
  | s488_p13
  | s488_p14
  | s488_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s488_p01 => []
  | .s488_p02 => []
  | .s488_p03 => [.s488_p01, .s488_p02]
  | .s488_p04 => [.s488_p01]
  | .s488_p05 => [.s488_p03]
  | .s488_p06 => [.s488_p04, .s488_p05]
  | .s488_p07 => [.s488_p04]
  | .s488_p08 => [.s488_p05]
  | .s488_p09 => [.s488_p06, .s488_p07]
  | .s488_p10 => [.s488_p07, .s488_p08]
  | .s488_p11 => [.s488_p09]
  | .s488_p12 => [.s488_p10]
  | .s488_p13 => [.s488_p09, .s488_p11]
  | .s488_p14 => [.s488_p11, .s488_p12]
  | .s488_p15 => [.s488_p13, .s488_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法令情報の誤りが業務違反を招くことを防ぐ絶対正確性要件 (ord=4) -/
  | LegalAccuracyInvariant
  /-- 法改正・ガイドライン更新の即時反映・バージョン管理方針 (ord=3) -/
  | RegulatoryUpdatePolicy
  /-- 受講者の理解度・職種・リスク領域に応じた研修カスタマイズ (ord=2) -/
  | LearnerAdaptationModel
  /-- 繰り返し学習・事例演習・定期テストによる定着率向上仮説 (ord=1) -/
  | KnowledgeRetentionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalAccuracyInvariant => 4
  | .RegulatoryUpdatePolicy => 3
  | .LearnerAdaptationModel => 2
  | .KnowledgeRetentionHypothesis => 1

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
  bottom := .KnowledgeRetentionHypothesis
  nontrivial := ⟨.LegalAccuracyInvariant, .KnowledgeRetentionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalAccuracyInvariant
  | .s488_p01 | .s488_p02 | .s488_p03 => .LegalAccuracyInvariant
  -- RegulatoryUpdatePolicy
  | .s488_p04 | .s488_p05 | .s488_p06 => .RegulatoryUpdatePolicy
  -- LearnerAdaptationModel
  | .s488_p07 | .s488_p08 | .s488_p09 | .s488_p10 => .LearnerAdaptationModel
  -- KnowledgeRetentionHypothesis
  | .s488_p11 | .s488_p12 | .s488_p13 | .s488_p14 | .s488_p15 => .KnowledgeRetentionHypothesis

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

end TestCoverage.S488
