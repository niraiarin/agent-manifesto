/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SecurityInvariant** (ord=3): スキャン対象システムへの損害・データ漏洩禁止の絶対不変条件 [C1, C2]
- **CompliancePolicy** (ord=2): CVSSスコアリング・開示ポリシー・スキャン認可要件の方針 [C3, C4, H1, H2]
- **DetectionHypothesis** (ord=1): 既知CVE照合・ゼロデイ推論・設定不備検出に関する仮説 [C5, H3, H4, H5]
-/

namespace TestCoverage.S345

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s345_p01
  | s345_p02
  | s345_p03
  | s345_p04
  | s345_p05
  | s345_p06
  | s345_p07
  | s345_p08
  | s345_p09
  | s345_p10
  | s345_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s345_p01 => []
  | .s345_p02 => []
  | .s345_p03 => [.s345_p01]
  | .s345_p04 => [.s345_p02]
  | .s345_p05 => [.s345_p03, .s345_p04]
  | .s345_p06 => [.s345_p03]
  | .s345_p07 => [.s345_p04]
  | .s345_p08 => [.s345_p05, .s345_p06]
  | .s345_p09 => [.s345_p07]
  | .s345_p10 => [.s345_p08, .s345_p09]
  | .s345_p11 => [.s345_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- スキャン対象システムへの損害・データ漏洩禁止の絶対不変条件 (ord=3) -/
  | SecurityInvariant
  /-- CVSSスコアリング・開示ポリシー・スキャン認可要件の方針 (ord=2) -/
  | CompliancePolicy
  /-- 既知CVE照合・ゼロデイ推論・設定不備検出に関する仮説 (ord=1) -/
  | DetectionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SecurityInvariant => 3
  | .CompliancePolicy => 2
  | .DetectionHypothesis => 1

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
  bottom := .DetectionHypothesis
  nontrivial := ⟨.SecurityInvariant, .DetectionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SecurityInvariant
  | .s345_p01 | .s345_p02 => .SecurityInvariant
  -- CompliancePolicy
  | .s345_p03 | .s345_p04 | .s345_p05 => .CompliancePolicy
  -- DetectionHypothesis
  | .s345_p06 | .s345_p07 | .s345_p08 | .s345_p09 | .s345_p10 | .s345_p11 => .DetectionHypothesis

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

end TestCoverage.S345
