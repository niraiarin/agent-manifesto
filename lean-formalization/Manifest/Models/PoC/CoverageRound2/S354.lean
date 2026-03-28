/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ProductSafetyInvariant** (ord=4): 出荷製品の安全性・欠陥品排除に関する絶対品質制約 [C1, C2]
- **StandardsCompliance** (ord=3): ISO 9001・JIS規格・業界品質基準への準拠要件 [C3, C4]
- **StatisticalProcessControl** (ord=2): 管理図・工程能力指数・サンプリング計画の統計的管理方針 [C5, H1, H2]
- **AnomalyDetectionHypothesis** (ord=1): 異常検知閾値・不良率予測・根本原因推定に関する統計仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S354

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s354_p01
  | s354_p02
  | s354_p03
  | s354_p04
  | s354_p05
  | s354_p06
  | s354_p07
  | s354_p08
  | s354_p09
  | s354_p10
  | s354_p11
  | s354_p12
  | s354_p13
  | s354_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s354_p01 => []
  | .s354_p02 => []
  | .s354_p03 => [.s354_p01]
  | .s354_p04 => [.s354_p02]
  | .s354_p05 => [.s354_p01, .s354_p02]
  | .s354_p06 => [.s354_p03]
  | .s354_p07 => [.s354_p04]
  | .s354_p08 => [.s354_p05]
  | .s354_p09 => [.s354_p06]
  | .s354_p10 => [.s354_p07]
  | .s354_p11 => [.s354_p08]
  | .s354_p12 => [.s354_p09]
  | .s354_p13 => [.s354_p10, .s354_p11]
  | .s354_p14 => [.s354_p12, .s354_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 出荷製品の安全性・欠陥品排除に関する絶対品質制約 (ord=4) -/
  | ProductSafetyInvariant
  /-- ISO 9001・JIS規格・業界品質基準への準拠要件 (ord=3) -/
  | StandardsCompliance
  /-- 管理図・工程能力指数・サンプリング計画の統計的管理方針 (ord=2) -/
  | StatisticalProcessControl
  /-- 異常検知閾値・不良率予測・根本原因推定に関する統計仮説 (ord=1) -/
  | AnomalyDetectionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ProductSafetyInvariant => 4
  | .StandardsCompliance => 3
  | .StatisticalProcessControl => 2
  | .AnomalyDetectionHypothesis => 1

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
  bottom := .AnomalyDetectionHypothesis
  nontrivial := ⟨.ProductSafetyInvariant, .AnomalyDetectionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ProductSafetyInvariant
  | .s354_p01 | .s354_p02 => .ProductSafetyInvariant
  -- StandardsCompliance
  | .s354_p03 | .s354_p04 | .s354_p05 => .StandardsCompliance
  -- StatisticalProcessControl
  | .s354_p06 | .s354_p07 | .s354_p08 => .StatisticalProcessControl
  -- AnomalyDetectionHypothesis
  | .s354_p09 | .s354_p10 | .s354_p11 | .s354_p12 | .s354_p13 | .s354_p14 => .AnomalyDetectionHypothesis

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

end TestCoverage.S354
