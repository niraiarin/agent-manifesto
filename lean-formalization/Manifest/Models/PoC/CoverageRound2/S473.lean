/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalComplianceInvariant** (ord=5): 区分所有法・建物管理規約への絶対的準拠条件 [C1, C2]
- **FinancialSoundnessPolicy** (ord=4): 修繕積立金・会計監査・予算管理の財務健全性ポリシー [C3, C4]
- **ResidentConsentPolicy** (ord=3): 総会決議・住民合意形成・議事録管理のポリシー [C5, H1]
- **MaintenancePlanningPolicy** (ord=2): 長期修繕計画・劣化診断・業者選定の計画方針 [C6, H2, H3]
- **PredictiveMaintenanceHypothesis** (ord=1): 建物劣化予測と修繕タイミング最適化に関する推論仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S473

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s473_p01
  | s473_p02
  | s473_p03
  | s473_p04
  | s473_p05
  | s473_p06
  | s473_p07
  | s473_p08
  | s473_p09
  | s473_p10
  | s473_p11
  | s473_p12
  | s473_p13
  | s473_p14
  | s473_p15
  | s473_p16
  | s473_p17
  | s473_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s473_p01 => []
  | .s473_p02 => []
  | .s473_p03 => [.s473_p01, .s473_p02]
  | .s473_p04 => [.s473_p01]
  | .s473_p05 => [.s473_p02]
  | .s473_p06 => [.s473_p04, .s473_p05]
  | .s473_p07 => [.s473_p03]
  | .s473_p08 => [.s473_p06]
  | .s473_p09 => [.s473_p07, .s473_p08]
  | .s473_p10 => [.s473_p04]
  | .s473_p11 => [.s473_p07]
  | .s473_p12 => [.s473_p09, .s473_p10]
  | .s473_p13 => [.s473_p10]
  | .s473_p14 => [.s473_p11]
  | .s473_p15 => [.s473_p12, .s473_p13]
  | .s473_p16 => [.s473_p14, .s473_p15]
  | .s473_p17 => [.s473_p11, .s473_p12]
  | .s473_p18 => [.s473_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 区分所有法・建物管理規約への絶対的準拠条件 (ord=5) -/
  | LegalComplianceInvariant
  /-- 修繕積立金・会計監査・予算管理の財務健全性ポリシー (ord=4) -/
  | FinancialSoundnessPolicy
  /-- 総会決議・住民合意形成・議事録管理のポリシー (ord=3) -/
  | ResidentConsentPolicy
  /-- 長期修繕計画・劣化診断・業者選定の計画方針 (ord=2) -/
  | MaintenancePlanningPolicy
  /-- 建物劣化予測と修繕タイミング最適化に関する推論仮説 (ord=1) -/
  | PredictiveMaintenanceHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalComplianceInvariant => 5
  | .FinancialSoundnessPolicy => 4
  | .ResidentConsentPolicy => 3
  | .MaintenancePlanningPolicy => 2
  | .PredictiveMaintenanceHypothesis => 1

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
  bottom := .PredictiveMaintenanceHypothesis
  nontrivial := ⟨.LegalComplianceInvariant, .PredictiveMaintenanceHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalComplianceInvariant
  | .s473_p01 | .s473_p02 | .s473_p03 => .LegalComplianceInvariant
  -- FinancialSoundnessPolicy
  | .s473_p04 | .s473_p05 | .s473_p06 | .s473_p18 => .FinancialSoundnessPolicy
  -- ResidentConsentPolicy
  | .s473_p07 | .s473_p08 | .s473_p09 => .ResidentConsentPolicy
  -- MaintenancePlanningPolicy
  | .s473_p10 | .s473_p11 | .s473_p12 | .s473_p17 => .MaintenancePlanningPolicy
  -- PredictiveMaintenanceHypothesis
  | .s473_p13 | .s473_p14 | .s473_p15 | .s473_p16 => .PredictiveMaintenanceHypothesis

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

end TestCoverage.S473
