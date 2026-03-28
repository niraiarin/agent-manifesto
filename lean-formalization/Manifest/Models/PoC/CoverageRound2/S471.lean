/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ComplianceInvariant** (ord=4): SOC2・ISO27001・PCI-DSS 等の規制要件への絶対的準拠条件 [C1, C2]
- **ThreatDetectionPolicy** (ord=3): 脅威インテリジェンス連携・異常検知ルールの強制ポリシー [C3, C4]
- **RemediationWorkflow** (ord=2): 脆弱性発見から修復完了までのエスカレーション・自動化方針 [C5, H1, H2]
- **PostureScoreHypothesis** (ord=1): セキュリティスコア計算モデルとリスク優先度付けに関する推論仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S471

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s471_p01
  | s471_p02
  | s471_p03
  | s471_p04
  | s471_p05
  | s471_p06
  | s471_p07
  | s471_p08
  | s471_p09
  | s471_p10
  | s471_p11
  | s471_p12
  | s471_p13
  | s471_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s471_p01 => []
  | .s471_p02 => []
  | .s471_p03 => [.s471_p01, .s471_p02]
  | .s471_p04 => [.s471_p01]
  | .s471_p05 => [.s471_p02]
  | .s471_p06 => [.s471_p04, .s471_p05]
  | .s471_p07 => [.s471_p04]
  | .s471_p08 => [.s471_p05]
  | .s471_p09 => [.s471_p06, .s471_p07]
  | .s471_p10 => [.s471_p07]
  | .s471_p11 => [.s471_p08]
  | .s471_p12 => [.s471_p09, .s471_p10]
  | .s471_p13 => [.s471_p11, .s471_p12]
  | .s471_p14 => [.s471_p08, .s471_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- SOC2・ISO27001・PCI-DSS 等の規制要件への絶対的準拠条件 (ord=4) -/
  | ComplianceInvariant
  /-- 脅威インテリジェンス連携・異常検知ルールの強制ポリシー (ord=3) -/
  | ThreatDetectionPolicy
  /-- 脆弱性発見から修復完了までのエスカレーション・自動化方針 (ord=2) -/
  | RemediationWorkflow
  /-- セキュリティスコア計算モデルとリスク優先度付けに関する推論仮説 (ord=1) -/
  | PostureScoreHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ComplianceInvariant => 4
  | .ThreatDetectionPolicy => 3
  | .RemediationWorkflow => 2
  | .PostureScoreHypothesis => 1

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
  bottom := .PostureScoreHypothesis
  nontrivial := ⟨.ComplianceInvariant, .PostureScoreHypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .s471_p01 | .s471_p02 | .s471_p03 => .ComplianceInvariant
  -- ThreatDetectionPolicy
  | .s471_p04 | .s471_p05 | .s471_p06 => .ThreatDetectionPolicy
  -- RemediationWorkflow
  | .s471_p07 | .s471_p08 | .s471_p09 | .s471_p14 => .RemediationWorkflow
  -- PostureScoreHypothesis
  | .s471_p10 | .s471_p11 | .s471_p12 | .s471_p13 => .PostureScoreHypothesis

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

end TestCoverage.S471
