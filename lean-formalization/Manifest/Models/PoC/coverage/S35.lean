/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **academic_integrity** (ord=4): 学術倫理・盗用検出・利益相反の原則 [C1, C2]
- **review_standard** (ord=3): 査読品質基準・評価フレームワーク [C3, C4, H1]
- **analysis_method** (ord=2): 論文分析手法・スコアリングモデル [C5, H2]
- **workflow_config** (ord=1): ワークフロー設定・通知・レポート形式 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | plagiarism_detection_mandatory
  | conflict_of_interest_check
  | double_blind_protocol
  | review_criteria_framework
  | statistical_rigor_check
  | novelty_assessment_model
  | citation_network_analysis
  | reviewer_matching_algorithm
  | deadline_management
  | notification_template
  | review_progress_dashboard
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .plagiarism_detection_mandatory => []
  | .conflict_of_interest_check => []
  | .double_blind_protocol => []
  | .review_criteria_framework => []
  | .statistical_rigor_check => []
  | .novelty_assessment_model => []
  | .citation_network_analysis => []
  | .reviewer_matching_algorithm => []
  | .deadline_management => []
  | .notification_template => []
  | .review_progress_dashboard => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 学術倫理・盗用検出・利益相反の原則 (ord=4) -/
  | academic_integrity
  /-- 査読品質基準・評価フレームワーク (ord=3) -/
  | review_standard
  /-- 論文分析手法・スコアリングモデル (ord=2) -/
  | analysis_method
  /-- ワークフロー設定・通知・レポート形式 (ord=1) -/
  | workflow_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .academic_integrity => 4
  | .review_standard => 3
  | .analysis_method => 2
  | .workflow_config => 1

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
  bottom := .workflow_config
  nontrivial := ⟨.academic_integrity, .workflow_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- academic_integrity
  | .plagiarism_detection_mandatory | .conflict_of_interest_check => .academic_integrity
  -- review_standard
  | .double_blind_protocol | .review_criteria_framework | .statistical_rigor_check => .review_standard
  -- analysis_method
  | .novelty_assessment_model | .citation_network_analysis | .reviewer_matching_algorithm => .analysis_method
  -- workflow_config
  | .deadline_management | .notification_template | .review_progress_dashboard => .workflow_config

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
