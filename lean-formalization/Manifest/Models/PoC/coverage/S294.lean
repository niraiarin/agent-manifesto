/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **neuro_safety** (ord=5): 神経刺激の安全上限に関する不変制約 [C1, C2]
- **medical_governance** (ord=4): 医師の処方・監督に関する制度的要件 [C4]
- **calibration_protocol** (ord=3): 個人キャリブレーションの手順・基準 [C3, H1]
- **stimulation_design** (ord=2): 刺激パターン生成の設計判断 [H2]
- **learning_hypothesis** (ord=1): 感覚マップ学習の仮説 [H3]
-/

namespace ProstheticTactileFeedback

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | pain_ceiling
  | emergency_stop
  | no_param_override
  | physician_approval
  | individual_calib
  | adaptation_monitor
  | recalib_trigger
  | vibrotactile_pref
  | pattern_encoding
  | sensory_map_ml
  | transfer_learning
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .pain_ceiling => []
  | .emergency_stop => []
  | .no_param_override => [.pain_ceiling]
  | .physician_approval => [.pain_ceiling, .emergency_stop]
  | .individual_calib => [.pain_ceiling, .physician_approval]
  | .adaptation_monitor => [.individual_calib]
  | .recalib_trigger => [.adaptation_monitor, .no_param_override]
  | .vibrotactile_pref => [.individual_calib]
  | .pattern_encoding => [.vibrotactile_pref, .pain_ceiling]
  | .sensory_map_ml => [.individual_calib, .pattern_encoding]
  | .transfer_learning => [.sensory_map_ml]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 神経刺激の安全上限に関する不変制約 (ord=5) -/
  | neuro_safety
  /-- 医師の処方・監督に関する制度的要件 (ord=4) -/
  | medical_governance
  /-- 個人キャリブレーションの手順・基準 (ord=3) -/
  | calibration_protocol
  /-- 刺激パターン生成の設計判断 (ord=2) -/
  | stimulation_design
  /-- 感覚マップ学習の仮説 (ord=1) -/
  | learning_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .neuro_safety => 5
  | .medical_governance => 4
  | .calibration_protocol => 3
  | .stimulation_design => 2
  | .learning_hypothesis => 1

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
  bottom := .learning_hypothesis
  nontrivial := ⟨.neuro_safety, .learning_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- neuro_safety
  | .pain_ceiling | .emergency_stop => .neuro_safety
  -- medical_governance
  | .no_param_override | .physician_approval => .medical_governance
  -- calibration_protocol
  | .individual_calib | .adaptation_monitor | .recalib_trigger => .calibration_protocol
  -- stimulation_design
  | .vibrotactile_pref | .pattern_encoding => .stimulation_design
  -- learning_hypothesis
  | .sensory_map_ml | .transfer_learning => .learning_hypothesis

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

end ProstheticTactileFeedback
