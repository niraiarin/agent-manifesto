/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **legal_compliance** (ord=4): 労働法・個人情報保護法・差別禁止法への準拠 [C1, C2]
- **fairness_standard** (ord=3): 公平性基準と評価指標の定義 [C3, H1]
- **evaluation_method** (ord=2): 面接評価手法・スコアリングモデル [C4, C5, H2]
- **ux_config** (ord=1): UI/UX設定・レポート形式・通知方法 [C6, H3]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | gdpr_compliance
  | anti_discrimination_law
  | demographic_parity_target
  | bias_audit_requirement
  | structured_interview_format
  | scoring_rubric_definition
  | llm_evaluation_boundary
  | candidate_feedback_format
  | interviewer_dashboard_layout
  | notification_timing
  | report_retention_period
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .gdpr_compliance => []
  | .anti_discrimination_law => []
  | .demographic_parity_target => []
  | .bias_audit_requirement => []
  | .structured_interview_format => []
  | .scoring_rubric_definition => []
  | .llm_evaluation_boundary => []
  | .candidate_feedback_format => []
  | .interviewer_dashboard_layout => []
  | .notification_timing => []
  | .report_retention_period => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 労働法・個人情報保護法・差別禁止法への準拠 (ord=4) -/
  | legal_compliance
  /-- 公平性基準と評価指標の定義 (ord=3) -/
  | fairness_standard
  /-- 面接評価手法・スコアリングモデル (ord=2) -/
  | evaluation_method
  /-- UI/UX設定・レポート形式・通知方法 (ord=1) -/
  | ux_config
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .legal_compliance => 4
  | .fairness_standard => 3
  | .evaluation_method => 2
  | .ux_config => 1

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
  bottom := .ux_config
  nontrivial := ⟨.legal_compliance, .ux_config, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- legal_compliance
  | .gdpr_compliance | .anti_discrimination_law => .legal_compliance
  -- fairness_standard
  | .demographic_parity_target | .bias_audit_requirement => .fairness_standard
  -- evaluation_method
  | .structured_interview_format | .scoring_rubric_definition | .llm_evaluation_boundary => .evaluation_method
  -- ux_config
  | .candidate_feedback_format | .interviewer_dashboard_layout | .notification_timing | .report_retention_period => .ux_config

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
