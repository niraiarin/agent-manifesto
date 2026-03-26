/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientDataIntegrity** (ord=4): 患者データの正確性・完全性・一貫性に関する絶対不変条件 [C1, C2]
- **PrivacyCompliance** (ord=3): 個人情報保護法・医療情報安全管理ガイドラインへの適合 [C3, C4]
- **ClinicalWorkflow** (ord=2): 診察・投薬・検査オーダーの業務フロー方針 [C5, C6, H1, H2]
- **InteroperabilityHypothesis** (ord=1): HL7 FHIR・既存レガシーシステムとの相互運用性に関する推論仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S341

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s341_p01
  | s341_p02
  | s341_p03
  | s341_p04
  | s341_p05
  | s341_p06
  | s341_p07
  | s341_p08
  | s341_p09
  | s341_p10
  | s341_p11
  | s341_p12
  | s341_p13
  | s341_p14
  | s341_p15
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s341_p01 => []
  | .s341_p02 => []
  | .s341_p03 => [.s341_p01, .s341_p02]
  | .s341_p04 => [.s341_p01]
  | .s341_p05 => [.s341_p02]
  | .s341_p06 => [.s341_p04, .s341_p05]
  | .s341_p07 => [.s341_p04]
  | .s341_p08 => [.s341_p05]
  | .s341_p09 => [.s341_p06, .s341_p07]
  | .s341_p10 => [.s341_p08]
  | .s341_p11 => [.s341_p07]
  | .s341_p12 => [.s341_p08]
  | .s341_p13 => [.s341_p11]
  | .s341_p14 => [.s341_p09, .s341_p12]
  | .s341_p15 => [.s341_p13, .s341_p14]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者データの正確性・完全性・一貫性に関する絶対不変条件 (ord=4) -/
  | PatientDataIntegrity
  /-- 個人情報保護法・医療情報安全管理ガイドラインへの適合 (ord=3) -/
  | PrivacyCompliance
  /-- 診察・投薬・検査オーダーの業務フロー方針 (ord=2) -/
  | ClinicalWorkflow
  /-- HL7 FHIR・既存レガシーシステムとの相互運用性に関する推論仮説 (ord=1) -/
  | InteroperabilityHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientDataIntegrity => 4
  | .PrivacyCompliance => 3
  | .ClinicalWorkflow => 2
  | .InteroperabilityHypothesis => 1

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
  bottom := .InteroperabilityHypothesis
  nontrivial := ⟨.PatientDataIntegrity, .InteroperabilityHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientDataIntegrity
  | .s341_p01 | .s341_p02 | .s341_p03 => .PatientDataIntegrity
  -- PrivacyCompliance
  | .s341_p04 | .s341_p05 | .s341_p06 => .PrivacyCompliance
  -- ClinicalWorkflow
  | .s341_p07 | .s341_p08 | .s341_p09 | .s341_p10 => .ClinicalWorkflow
  -- InteroperabilityHypothesis
  | .s341_p11 | .s341_p12 | .s341_p13 | .s341_p14 | .s341_p15 => .InteroperabilityHypothesis

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

end TestCoverage.S341
