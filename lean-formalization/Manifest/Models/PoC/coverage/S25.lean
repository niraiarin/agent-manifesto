/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **child_safety_constraint** (ord=5): 子どもの安全と権利の保護。絶対的制約 [C1, C2]
- **developmental_postulate** (ord=4): 発達心理学・小児医学の科学的知見 [C3, H1]
- **parenting_principle** (ord=2): 育児方針の原則。家庭の価値観を尊重 [C4, C5, C6, H2]
- **advice_hypothesis** (ord=0): 具体的アドバイスの仮説。エビデンスで更新 [H3, H4, H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | emergency_escalation
  | no_medical_diagnosis
  | age_appropriate_milestones
  | attachment_theory_basis
  | respect_cultural_diversity
  | parent_autonomy
  | evidence_based_only
  | sleep_training_method
  | screen_time_recommendation
  | feeding_schedule_suggestion
  | developmental_delay_alert
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .emergency_escalation => []
  | .no_medical_diagnosis => []
  | .age_appropriate_milestones => []
  | .attachment_theory_basis => []
  | .respect_cultural_diversity => []
  | .parent_autonomy => []
  | .evidence_based_only => []
  | .sleep_training_method => []
  | .screen_time_recommendation => []
  | .feeding_schedule_suggestion => []
  | .developmental_delay_alert => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 子どもの安全と権利の保護。絶対的制約 (ord=5) -/
  | child_safety_constraint
  /-- 発達心理学・小児医学の科学的知見 (ord=4) -/
  | developmental_postulate
  /-- 育児方針の原則。家庭の価値観を尊重 (ord=2) -/
  | parenting_principle
  /-- 具体的アドバイスの仮説。エビデンスで更新 (ord=0) -/
  | advice_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .child_safety_constraint => 5
  | .developmental_postulate => 4
  | .parenting_principle => 2
  | .advice_hypothesis => 0

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
  bottom := .advice_hypothesis
  nontrivial := ⟨.child_safety_constraint, .advice_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- child_safety_constraint
  | .emergency_escalation | .no_medical_diagnosis | .developmental_delay_alert => .child_safety_constraint
  -- developmental_postulate
  | .age_appropriate_milestones | .attachment_theory_basis => .developmental_postulate
  -- parenting_principle
  | .respect_cultural_diversity | .parent_autonomy | .evidence_based_only => .parenting_principle
  -- advice_hypothesis
  | .sleep_training_method | .screen_time_recommendation | .feeding_schedule_suggestion => .advice_hypothesis

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

end Manifest.Models
