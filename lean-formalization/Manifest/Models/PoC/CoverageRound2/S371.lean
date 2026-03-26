/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetyInvariant** (ord=4): 患者の誤診・見逃しを防ぐための絶対不変条件 [C1, C2]
- **RegulatoryApproval** (ord=3): 薬機法・FDA・CE認証への適合要件 [C3, C4]
- **ClinicalWorkflowPolicy** (ord=2): 放射線科医との協調・報告書生成・優先度付けの方針 [C5, H1, H2]
- **DiagnosticModelHypothesis** (ord=1): 病変検出モデルの精度・汎化に関する推論仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S371

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s371_p01
  | s371_p02
  | s371_p03
  | s371_p04
  | s371_p05
  | s371_p06
  | s371_p07
  | s371_p08
  | s371_p09
  | s371_p10
  | s371_p11
  | s371_p12
  | s371_p13
  | s371_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s371_p01 => []
  | .s371_p02 => []
  | .s371_p03 => [.s371_p01, .s371_p02]
  | .s371_p04 => [.s371_p01]
  | .s371_p05 => [.s371_p02]
  | .s371_p06 => [.s371_p04, .s371_p05]
  | .s371_p07 => [.s371_p04]
  | .s371_p08 => [.s371_p05]
  | .s371_p09 => [.s371_p06, .s371_p07]
  | .s371_p10 => [.s371_p07]
  | .s371_p11 => [.s371_p08]
  | .s371_p12 => [.s371_p09, .s371_p10]
  | .s371_p13 => [.s371_p10, .s371_p11]
  | .s371_p14 => [.s371_p12, .s371_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の誤診・見逃しを防ぐための絶対不変条件 (ord=4) -/
  | PatientSafetyInvariant
  /-- 薬機法・FDA・CE認証への適合要件 (ord=3) -/
  | RegulatoryApproval
  /-- 放射線科医との協調・報告書生成・優先度付けの方針 (ord=2) -/
  | ClinicalWorkflowPolicy
  /-- 病変検出モデルの精度・汎化に関する推論仮説 (ord=1) -/
  | DiagnosticModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetyInvariant => 4
  | .RegulatoryApproval => 3
  | .ClinicalWorkflowPolicy => 2
  | .DiagnosticModelHypothesis => 1

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
  bottom := .DiagnosticModelHypothesis
  nontrivial := ⟨.PatientSafetyInvariant, .DiagnosticModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafetyInvariant
  | .s371_p01 | .s371_p02 | .s371_p03 => .PatientSafetyInvariant
  -- RegulatoryApproval
  | .s371_p04 | .s371_p05 | .s371_p06 => .RegulatoryApproval
  -- ClinicalWorkflowPolicy
  | .s371_p07 | .s371_p08 | .s371_p09 => .ClinicalWorkflowPolicy
  -- DiagnosticModelHypothesis
  | .s371_p10 | .s371_p11 | .s371_p12 | .s371_p13 | .s371_p14 => .DiagnosticModelHypothesis

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

end TestCoverage.S371
