/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PatientSafety** (ord=4): リハビリ患者の身体的安全・二次障害防止に関する絶対不変条件 [C1, C2]
- **ClinicalCompliance** (ord=3): 医師・理学療法士の指示・医療機器規制への適合要件 [C3, C4]
- **TherapyPolicy** (ord=2): 負荷調整・反復動作・疲労検知に基づくリハビリ方針 [C5, C6, H1, H2]
- **AdaptationHypothesis** (ord=1): 患者回復曲線・動作パターン適応に関する推論仮説 [H3, H4, H5, H6, H7]
-/

namespace TestCoverage.S361

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s361_p01
  | s361_p02
  | s361_p03
  | s361_p04
  | s361_p05
  | s361_p06
  | s361_p07
  | s361_p08
  | s361_p09
  | s361_p10
  | s361_p11
  | s361_p12
  | s361_p13
  | s361_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s361_p01 => []
  | .s361_p02 => []
  | .s361_p03 => [.s361_p01]
  | .s361_p04 => [.s361_p01]
  | .s361_p05 => [.s361_p02]
  | .s361_p06 => [.s361_p04, .s361_p05]
  | .s361_p07 => [.s361_p04]
  | .s361_p08 => [.s361_p05]
  | .s361_p09 => [.s361_p03, .s361_p07]
  | .s361_p10 => [.s361_p07]
  | .s361_p11 => [.s361_p08]
  | .s361_p12 => [.s361_p09, .s361_p10]
  | .s361_p13 => [.s361_p11]
  | .s361_p14 => [.s361_p12, .s361_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- リハビリ患者の身体的安全・二次障害防止に関する絶対不変条件 (ord=4) -/
  | PatientSafety
  /-- 医師・理学療法士の指示・医療機器規制への適合要件 (ord=3) -/
  | ClinicalCompliance
  /-- 負荷調整・反復動作・疲労検知に基づくリハビリ方針 (ord=2) -/
  | TherapyPolicy
  /-- 患者回復曲線・動作パターン適応に関する推論仮説 (ord=1) -/
  | AdaptationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PatientSafety => 4
  | .ClinicalCompliance => 3
  | .TherapyPolicy => 2
  | .AdaptationHypothesis => 1

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
  bottom := .AdaptationHypothesis
  nontrivial := ⟨.PatientSafety, .AdaptationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PatientSafety
  | .s361_p01 | .s361_p02 | .s361_p03 => .PatientSafety
  -- ClinicalCompliance
  | .s361_p04 | .s361_p05 | .s361_p06 => .ClinicalCompliance
  -- TherapyPolicy
  | .s361_p07 | .s361_p08 | .s361_p09 => .TherapyPolicy
  -- AdaptationHypothesis
  | .s361_p10 | .s361_p11 | .s361_p12 | .s361_p13 | .s361_p14 => .AdaptationHypothesis

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

end TestCoverage.S361
