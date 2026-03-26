/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **athlete_safety_constraint** (ord=5): 選手の健康・安全に関する制約。怪我予防が最優先 [C1, C2]
- **sports_science_postulate** (ord=4): スポーツ科学・運動生理学の前提 [C3, H1, H2]
- **coaching_principle** (ord=2): コーチングの原則。データと経験のバランス [C4, C5, H3]
- **metric_hypothesis** (ord=0): パフォーマンス指標の仮説。シーズンデータで検証 [H4, H5, H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | injury_risk_threshold
  | anti_doping_compliance
  | biomechanical_model
  | physiological_load_monitoring
  | coach_override_authority
  | training_periodization
  | sprint_speed_benchmark
  | fatigue_index_formula
  | match_readiness_score
  | recovery_protocol
  | tactical_pattern_detection
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .injury_risk_threshold => []
  | .anti_doping_compliance => []
  | .biomechanical_model => []
  | .physiological_load_monitoring => []
  | .coach_override_authority => []
  | .training_periodization => []
  | .sprint_speed_benchmark => []
  | .fatigue_index_formula => []
  | .match_readiness_score => []
  | .recovery_protocol => []
  | .tactical_pattern_detection => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 選手の健康・安全に関する制約。怪我予防が最優先 (ord=5) -/
  | athlete_safety_constraint
  /-- スポーツ科学・運動生理学の前提 (ord=4) -/
  | sports_science_postulate
  /-- コーチングの原則。データと経験のバランス (ord=2) -/
  | coaching_principle
  /-- パフォーマンス指標の仮説。シーズンデータで検証 (ord=0) -/
  | metric_hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .athlete_safety_constraint => 5
  | .sports_science_postulate => 4
  | .coaching_principle => 2
  | .metric_hypothesis => 0

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
  bottom := .metric_hypothesis
  nontrivial := ⟨.athlete_safety_constraint, .metric_hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- athlete_safety_constraint
  | .injury_risk_threshold | .anti_doping_compliance => .athlete_safety_constraint
  -- sports_science_postulate
  | .biomechanical_model | .physiological_load_monitoring | .recovery_protocol => .sports_science_postulate
  -- coaching_principle
  | .coach_override_authority | .training_periodization | .tactical_pattern_detection => .coaching_principle
  -- metric_hypothesis
  | .sprint_speed_benchmark | .fatigue_index_formula | .match_readiness_score => .metric_hypothesis

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
