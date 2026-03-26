/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SystemAvailabilityInvariant** (ord=4): インシデント見逃し・誤検知爆発を防ぐ可用性不変条件 [C1, C2]
- **SecurityCompliancePolicy** (ord=3): SOC2・PCI-DSS監査ログ保全・アクセス制御要件 [C3, C4]
- **AlertTriagePolicy** (ord=2): アラート優先度付け・エスカレーション・抑制ルールの方針 [H1, H2]
- **AnomalyDetectionHypothesis** (ord=1): ベースライン学習・時系列異常スコアリングの推論仮説 [C5, H3, H4, H5]
-/

namespace TestCoverage.S375

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s375_p01
  | s375_p02
  | s375_p03
  | s375_p04
  | s375_p05
  | s375_p06
  | s375_p07
  | s375_p08
  | s375_p09
  | s375_p10
  | s375_p11
  | s375_p12
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s375_p01 => []
  | .s375_p02 => []
  | .s375_p03 => [.s375_p01]
  | .s375_p04 => [.s375_p02]
  | .s375_p05 => [.s375_p03, .s375_p04]
  | .s375_p06 => [.s375_p03]
  | .s375_p07 => [.s375_p04, .s375_p06]
  | .s375_p08 => [.s375_p05]
  | .s375_p09 => [.s375_p06]
  | .s375_p10 => [.s375_p07]
  | .s375_p11 => [.s375_p08, .s375_p09]
  | .s375_p12 => [.s375_p10, .s375_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- インシデント見逃し・誤検知爆発を防ぐ可用性不変条件 (ord=4) -/
  | SystemAvailabilityInvariant
  /-- SOC2・PCI-DSS監査ログ保全・アクセス制御要件 (ord=3) -/
  | SecurityCompliancePolicy
  /-- アラート優先度付け・エスカレーション・抑制ルールの方針 (ord=2) -/
  | AlertTriagePolicy
  /-- ベースライン学習・時系列異常スコアリングの推論仮説 (ord=1) -/
  | AnomalyDetectionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SystemAvailabilityInvariant => 4
  | .SecurityCompliancePolicy => 3
  | .AlertTriagePolicy => 2
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
  nontrivial := ⟨.SystemAvailabilityInvariant, .AnomalyDetectionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SystemAvailabilityInvariant
  | .s375_p01 | .s375_p02 => .SystemAvailabilityInvariant
  -- SecurityCompliancePolicy
  | .s375_p03 | .s375_p04 | .s375_p05 => .SecurityCompliancePolicy
  -- AlertTriagePolicy
  | .s375_p06 | .s375_p07 => .AlertTriagePolicy
  -- AnomalyDetectionHypothesis
  | .s375_p08 | .s375_p09 | .s375_p10 | .s375_p11 | .s375_p12 => .AnomalyDetectionHypothesis

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

end TestCoverage.S375
