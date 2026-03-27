/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafety** (ord=6): 患者の生命・健康に直結する安全制約 [C1]
- **MedicalEthics** (ord=5): 医療倫理・守秘義務。法的・倫理的義務 [C2, C3]
- **ClinicalEvidence** (ord=4): エビデンスに基づく臨床判断基準 [C4, H1]
- **InstitutionalPolicy** (ord=3): 病院の運用ポリシー。組織判断で変更可能 [C5, H2]
- **WorkflowOptimization** (ord=2): 業務効率化ルール。現場データに基づき調整 [H3, H4]
- **UIPreference** (ord=1): 医師個人のインターフェース設定 [C6, H5]
-/

namespace TestCoverage.S2

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s2_p01
  | s2_p02
  | s2_p03
  | s2_p04
  | s2_p05
  | s2_p06
  | s2_p07
  | s2_p08
  | s2_p09
  | s2_p10
  | s2_p11
  | s2_p12
  | s2_p13
  | s2_p14
  | s2_p15
  | s2_p16
  | s2_p17
  | s2_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s2_p01 => []
  | .s2_p02 => []
  | .s2_p03 => [.s2_p01]
  | .s2_p04 => [.s2_p01]
  | .s2_p05 => [.s2_p01, .s2_p02]
  | .s2_p06 => [.s2_p03]
  | .s2_p07 => [.s2_p04]
  | .s2_p08 => [.s2_p03, .s2_p05]
  | .s2_p09 => [.s2_p06]
  | .s2_p10 => [.s2_p07]
  | .s2_p11 => [.s2_p06, .s2_p08]
  | .s2_p12 => [.s2_p09]
  | .s2_p13 => [.s2_p10]
  | .s2_p14 => [.s2_p09, .s2_p11]
  | .s2_p15 => [.s2_p12]
  | .s2_p16 => [.s2_p13]
  | .s2_p17 => [.s2_p14]
  | .s2_p18 => [.s2_p15, .s2_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の生命・健康に直結する安全制約 (ord=6) -/
  | PatientSafety
  /-- 医療倫理・守秘義務。法的・倫理的義務 (ord=5) -/
  | MedicalEthics
  /-- エビデンスに基づく臨床判断基準 (ord=4) -/
  | ClinicalEvidence
  /-- 病院の運用ポリシー。組織判断で変更可能 (ord=3) -/
  | InstitutionalPolicy
  /-- 業務効率化ルール。現場データに基づき調整 (ord=2) -/
  | WorkflowOptimization
  /-- 医師個人のインターフェース設定 (ord=1) -/
  | UIPreference
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafety => 6
  | .MedicalEthics => 5
  | .ClinicalEvidence => 4
  | .InstitutionalPolicy => 3
  | .WorkflowOptimization => 2
  | .UIPreference => 1

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
  bottom := .UIPreference
  nontrivial := ⟨.PatientSafety, .UIPreference, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafety
  | .s2_p01 | .s2_p02 => .PatientSafety
  -- MedicalEthics
  | .s2_p03 | .s2_p04 | .s2_p05 => .MedicalEthics
  -- ClinicalEvidence
  | .s2_p06 | .s2_p07 | .s2_p08 => .ClinicalEvidence
  -- InstitutionalPolicy
  | .s2_p09 | .s2_p10 | .s2_p11 => .InstitutionalPolicy
  -- WorkflowOptimization
  | .s2_p12 | .s2_p13 | .s2_p14 => .WorkflowOptimization
  -- UIPreference
  | .s2_p15 | .s2_p16 | .s2_p17 | .s2_p18 => .UIPreference

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

end TestCoverage.S2
