/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafetyInvariant** (ord=4): 患者の生命・精神的安全に関わる不変制約。いかなる状況でも優先される [C1, C2]
- **ClinicalEthicsCompliance** (ord=3): 医療倫理・守秘義務・インフォームドコンセントへの準拠。法的義務 [C3, H1]
- **AssessmentPolicy** (ord=2): スクリーニング実施方針。臨床判断に基づく運用ルール [C4, H2, H3]
- **AdaptiveHypothesis** (ord=1): 個別化スクリーニング改善の仮説。検証データに基づき調整可能 [H4, H5, H6]
-/

namespace TestCoverage.S401

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s401_p01
  | s401_p02
  | s401_p03
  | s401_p04
  | s401_p05
  | s401_p06
  | s401_p07
  | s401_p08
  | s401_p09
  | s401_p10
  | s401_p11
  | s401_p12
  | s401_p13
  | s401_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s401_p01 => []
  | .s401_p02 => []
  | .s401_p03 => [.s401_p01, .s401_p02]
  | .s401_p04 => [.s401_p01]
  | .s401_p05 => [.s401_p02]
  | .s401_p06 => [.s401_p03]
  | .s401_p07 => [.s401_p04]
  | .s401_p08 => [.s401_p05]
  | .s401_p09 => [.s401_p06]
  | .s401_p10 => [.s401_p07, .s401_p08]
  | .s401_p11 => [.s401_p07]
  | .s401_p12 => [.s401_p08]
  | .s401_p13 => [.s401_p09]
  | .s401_p14 => [.s401_p10, .s401_p11, .s401_p12]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の生命・精神的安全に関わる不変制約。いかなる状況でも優先される (ord=4) -/
  | PatientSafetyInvariant
  /-- 医療倫理・守秘義務・インフォームドコンセントへの準拠。法的義務 (ord=3) -/
  | ClinicalEthicsCompliance
  /-- スクリーニング実施方針。臨床判断に基づく運用ルール (ord=2) -/
  | AssessmentPolicy
  /-- 個別化スクリーニング改善の仮説。検証データに基づき調整可能 (ord=1) -/
  | AdaptiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafetyInvariant => 4
  | .ClinicalEthicsCompliance => 3
  | .AssessmentPolicy => 2
  | .AdaptiveHypothesis => 1

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
  bottom := .AdaptiveHypothesis
  nontrivial := ⟨.PatientSafetyInvariant, .AdaptiveHypothesis, by simp [ConcreteLayer.ord]⟩
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
  | .s401_p01 | .s401_p02 | .s401_p03 => .PatientSafetyInvariant
  -- ClinicalEthicsCompliance
  | .s401_p04 | .s401_p05 | .s401_p06 => .ClinicalEthicsCompliance
  -- AssessmentPolicy
  | .s401_p07 | .s401_p08 | .s401_p09 | .s401_p10 => .AssessmentPolicy
  -- AdaptiveHypothesis
  | .s401_p11 | .s401_p12 | .s401_p13 | .s401_p14 => .AdaptiveHypothesis

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

end TestCoverage.S401
