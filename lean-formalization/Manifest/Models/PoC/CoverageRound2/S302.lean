/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafety** (ord=5): 患者の生命・健康を守る最上位不変条件 [C1, C2]
- **LegalCompliance** (ord=4): 医師法・個人情報保護法・遠隔診療ガイドラインへの適合 [C3]
- **ClinicalPolicy** (ord=3): 診断支援・処方制限・緊急搬送の臨床方針 [C4, C5, H1]
- **SystemReliability** (ord=2): 通信品質・バックアップ・可用性に関する方針 [H2, H3]
- **DiagnosticHypothesis** (ord=1): 症状推定・疾患分類に関するML推論仮説 [H4, H5, H6]
-/

namespace TestCoverage.S302

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s302_p01
  | s302_p02
  | s302_p03
  | s302_p04
  | s302_p05
  | s302_p06
  | s302_p07
  | s302_p08
  | s302_p09
  | s302_p10
  | s302_p11
  | s302_p12
  | s302_p13
  | s302_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s302_p01 => []
  | .s302_p02 => []
  | .s302_p03 => [.s302_p01]
  | .s302_p04 => [.s302_p01, .s302_p03]
  | .s302_p05 => [.s302_p02]
  | .s302_p06 => [.s302_p03]
  | .s302_p07 => [.s302_p04]
  | .s302_p08 => [.s302_p05]
  | .s302_p09 => [.s302_p06, .s302_p07]
  | .s302_p10 => [.s302_p07]
  | .s302_p11 => [.s302_p08]
  | .s302_p12 => [.s302_p09]
  | .s302_p13 => [.s302_p10, .s302_p11]
  | .s302_p14 => [.s302_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の生命・健康を守る最上位不変条件 (ord=5) -/
  | PatientSafety
  /-- 医師法・個人情報保護法・遠隔診療ガイドラインへの適合 (ord=4) -/
  | LegalCompliance
  /-- 診断支援・処方制限・緊急搬送の臨床方針 (ord=3) -/
  | ClinicalPolicy
  /-- 通信品質・バックアップ・可用性に関する方針 (ord=2) -/
  | SystemReliability
  /-- 症状推定・疾患分類に関するML推論仮説 (ord=1) -/
  | DiagnosticHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafety => 5
  | .LegalCompliance => 4
  | .ClinicalPolicy => 3
  | .SystemReliability => 2
  | .DiagnosticHypothesis => 1

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
  bottom := .DiagnosticHypothesis
  nontrivial := ⟨.PatientSafety, .DiagnosticHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafety
  | .s302_p01 | .s302_p02 => .PatientSafety
  -- LegalCompliance
  | .s302_p03 => .LegalCompliance
  -- ClinicalPolicy
  | .s302_p04 | .s302_p05 | .s302_p06 => .ClinicalPolicy
  -- SystemReliability
  | .s302_p07 | .s302_p08 | .s302_p09 => .SystemReliability
  -- DiagnosticHypothesis
  | .s302_p10 | .s302_p11 | .s302_p12 | .s302_p13 | .s302_p14 => .DiagnosticHypothesis

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

end TestCoverage.S302
