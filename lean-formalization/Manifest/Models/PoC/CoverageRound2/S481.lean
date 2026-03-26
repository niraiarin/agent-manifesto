/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetyInvariant** (ord=4): 骨・歯根・神経への不可逆的損傷を防ぐ絶対不変条件 [C1, C2]
- **ClinicalRegulationPolicy** (ord=3): 歯科医師法・医療機器規制・インフォームドコンセント要件 [C3, C4]
- **TreatmentPlanningModel** (ord=2): 歯列移動量・保定期間・装置選択に関するモデル推論 [C5, H1, H2]
- **PredictiveOutcomeHypothesis** (ord=1): 治療後の審美結果・後戻りリスクに関する予測仮説 [H3, H4, H5, H6]
-/

namespace TestCoverage.S481

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s481_p01
  | s481_p02
  | s481_p03
  | s481_p04
  | s481_p05
  | s481_p06
  | s481_p07
  | s481_p08
  | s481_p09
  | s481_p10
  | s481_p11
  | s481_p12
  | s481_p13
  | s481_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s481_p01 => []
  | .s481_p02 => []
  | .s481_p03 => [.s481_p01, .s481_p02]
  | .s481_p04 => [.s481_p01]
  | .s481_p05 => [.s481_p03]
  | .s481_p06 => [.s481_p04, .s481_p05]
  | .s481_p07 => [.s481_p04]
  | .s481_p08 => [.s481_p05]
  | .s481_p09 => [.s481_p06, .s481_p07]
  | .s481_p10 => [.s481_p07]
  | .s481_p11 => [.s481_p08]
  | .s481_p12 => [.s481_p09, .s481_p10]
  | .s481_p13 => [.s481_p10, .s481_p11]
  | .s481_p14 => [.s481_p12, .s481_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 骨・歯根・神経への不可逆的損傷を防ぐ絶対不変条件 (ord=4) -/
  | PatientSafetyInvariant
  /-- 歯科医師法・医療機器規制・インフォームドコンセント要件 (ord=3) -/
  | ClinicalRegulationPolicy
  /-- 歯列移動量・保定期間・装置選択に関するモデル推論 (ord=2) -/
  | TreatmentPlanningModel
  /-- 治療後の審美結果・後戻りリスクに関する予測仮説 (ord=1) -/
  | PredictiveOutcomeHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetyInvariant => 4
  | .ClinicalRegulationPolicy => 3
  | .TreatmentPlanningModel => 2
  | .PredictiveOutcomeHypothesis => 1

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
  bottom := .PredictiveOutcomeHypothesis
  nontrivial := ⟨.PatientSafetyInvariant, .PredictiveOutcomeHypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .s481_p01 | .s481_p02 | .s481_p03 => .PatientSafetyInvariant
  -- ClinicalRegulationPolicy
  | .s481_p04 | .s481_p05 | .s481_p06 => .ClinicalRegulationPolicy
  -- TreatmentPlanningModel
  | .s481_p07 | .s481_p08 | .s481_p09 => .TreatmentPlanningModel
  -- PredictiveOutcomeHypothesis
  | .s481_p10 | .s481_p11 | .s481_p12 | .s481_p13 | .s481_p14 => .PredictiveOutcomeHypothesis

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

end TestCoverage.S481
