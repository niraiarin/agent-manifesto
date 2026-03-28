/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **UserPrivacySecurityInvariant** (ord=3): 個人情報漏洩・金融詐欺被害の発生を防ぐ絶対不変条件 [C1, C2]
- **ComplianceDetectionPolicy** (ord=2): GDPR・サイバーセキュリティ法・誤検知率上限の遵守方針 [C3, C4, C5]
- **ThreatIntelligenceHypothesis** (ord=1): URLパターン・送信元評判・コンテンツ類似度による脅威推論 [H1, H2, H3, H4, H5]
-/

namespace TestCoverage.S485

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s485_p01
  | s485_p02
  | s485_p03
  | s485_p04
  | s485_p05
  | s485_p06
  | s485_p07
  | s485_p08
  | s485_p09
  | s485_p10
  | s485_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s485_p01 => []
  | .s485_p02 => []
  | .s485_p03 => [.s485_p01, .s485_p02]
  | .s485_p04 => [.s485_p01]
  | .s485_p05 => [.s485_p02, .s485_p03]
  | .s485_p06 => [.s485_p04, .s485_p05]
  | .s485_p07 => [.s485_p04]
  | .s485_p08 => [.s485_p05]
  | .s485_p09 => [.s485_p06, .s485_p07]
  | .s485_p10 => [.s485_p07, .s485_p08]
  | .s485_p11 => [.s485_p09, .s485_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 個人情報漏洩・金融詐欺被害の発生を防ぐ絶対不変条件 (ord=3) -/
  | UserPrivacySecurityInvariant
  /-- GDPR・サイバーセキュリティ法・誤検知率上限の遵守方針 (ord=2) -/
  | ComplianceDetectionPolicy
  /-- URLパターン・送信元評判・コンテンツ類似度による脅威推論 (ord=1) -/
  | ThreatIntelligenceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .UserPrivacySecurityInvariant => 3
  | .ComplianceDetectionPolicy => 2
  | .ThreatIntelligenceHypothesis => 1

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
  bottom := .ThreatIntelligenceHypothesis
  nontrivial := ⟨.UserPrivacySecurityInvariant, .ThreatIntelligenceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- UserPrivacySecurityInvariant
  | .s485_p01 | .s485_p02 | .s485_p03 => .UserPrivacySecurityInvariant
  -- ComplianceDetectionPolicy
  | .s485_p04 | .s485_p05 | .s485_p06 => .ComplianceDetectionPolicy
  -- ThreatIntelligenceHypothesis
  | .s485_p07 | .s485_p08 | .s485_p09 | .s485_p10 | .s485_p11 => .ThreatIntelligenceHypothesis

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

end TestCoverage.S485
