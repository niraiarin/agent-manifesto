/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **WorkerRightsInvariant** (ord=7): 労働者の基本権・安全衛生・差別禁止に関する絶対不変条件 [C1]
- **LegalCompliance** (ord=6): 労働基準法・労働安全衛生法・男女雇用機会均等法への準拠 [C2, C3]
- **PrivacyProtection** (ord=5): 従業員個人情報・健康情報・行動データの保護要件 [C4]
- **HRPolicy** (ord=4): 人事評価基準・介入タイミング・エスカレーション手順に関するHRポリシー [C5, C6, H1]
- **RiskAssessmentModel** (ord=3): 離職リスク・健康リスク・ハラスメントリスクの評価モデル [H2, H3, H4]
- **InterventionStrategy** (ord=2): 早期介入・メンタルヘルス支援・職場改善に関する介入戦略 [H5, H6]
- **AdaptiveLearning** (ord=1): フィードバックループ・モデル更新・組織学習に関する適応学習仮説 [H7, H8]
-/

namespace TestCoverage.S498

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s498_p01
  | s498_p02
  | s498_p03
  | s498_p04
  | s498_p05
  | s498_p06
  | s498_p07
  | s498_p08
  | s498_p09
  | s498_p10
  | s498_p11
  | s498_p12
  | s498_p13
  | s498_p14
  | s498_p15
  | s498_p16
  | s498_p17
  | s498_p18
  | s498_p19
  | s498_p20
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s498_p01 => []
  | .s498_p02 => [.s498_p01]
  | .s498_p03 => [.s498_p01]
  | .s498_p04 => [.s498_p02, .s498_p03]
  | .s498_p05 => [.s498_p02]
  | .s498_p06 => [.s498_p04, .s498_p05]
  | .s498_p07 => [.s498_p04]
  | .s498_p08 => [.s498_p05]
  | .s498_p09 => [.s498_p06, .s498_p07]
  | .s498_p10 => [.s498_p07]
  | .s498_p11 => [.s498_p08]
  | .s498_p12 => [.s498_p09, .s498_p10]
  | .s498_p13 => [.s498_p11, .s498_p12]
  | .s498_p14 => [.s498_p10]
  | .s498_p15 => [.s498_p11]
  | .s498_p16 => [.s498_p12, .s498_p14]
  | .s498_p17 => [.s498_p13]
  | .s498_p18 => [.s498_p14]
  | .s498_p19 => [.s498_p15, .s498_p17]
  | .s498_p20 => [.s498_p16, .s498_p18, .s498_p19]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 労働者の基本権・安全衛生・差別禁止に関する絶対不変条件 (ord=7) -/
  | WorkerRightsInvariant
  /-- 労働基準法・労働安全衛生法・男女雇用機会均等法への準拠 (ord=6) -/
  | LegalCompliance
  /-- 従業員個人情報・健康情報・行動データの保護要件 (ord=5) -/
  | PrivacyProtection
  /-- 人事評価基準・介入タイミング・エスカレーション手順に関するHRポリシー (ord=4) -/
  | HRPolicy
  /-- 離職リスク・健康リスク・ハラスメントリスクの評価モデル (ord=3) -/
  | RiskAssessmentModel
  /-- 早期介入・メンタルヘルス支援・職場改善に関する介入戦略 (ord=2) -/
  | InterventionStrategy
  /-- フィードバックループ・モデル更新・組織学習に関する適応学習仮説 (ord=1) -/
  | AdaptiveLearning
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .WorkerRightsInvariant => 7
  | .LegalCompliance => 6
  | .PrivacyProtection => 5
  | .HRPolicy => 4
  | .RiskAssessmentModel => 3
  | .InterventionStrategy => 2
  | .AdaptiveLearning => 1

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
  bottom := .AdaptiveLearning
  nontrivial := ⟨.WorkerRightsInvariant, .AdaptiveLearning, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨7, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- WorkerRightsInvariant
  | .s498_p01 => .WorkerRightsInvariant
  -- LegalCompliance
  | .s498_p02 | .s498_p03 | .s498_p04 => .LegalCompliance
  -- PrivacyProtection
  | .s498_p05 | .s498_p06 => .PrivacyProtection
  -- HRPolicy
  | .s498_p07 | .s498_p08 | .s498_p09 => .HRPolicy
  -- RiskAssessmentModel
  | .s498_p10 | .s498_p11 | .s498_p12 | .s498_p13 => .RiskAssessmentModel
  -- InterventionStrategy
  | .s498_p14 | .s498_p15 | .s498_p16 => .InterventionStrategy
  -- AdaptiveLearning
  | .s498_p17 | .s498_p18 | .s498_p19 | .s498_p20 => .AdaptiveLearning

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

end TestCoverage.S498
