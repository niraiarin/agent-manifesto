/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LifeSafetyAbsolute** (ord=5): 患者の生命維持に直結する絶対制約。いかなる判断も生命安全を下回ることはできない [C1, C2]
- **MedicalEthicsCompliance** (ord=4): 医療倫理・インフォームドコンセント・守秘義務に関する規範的制約 [C3, C4]
- **ClinicalProtocol** (ord=3): トリアージ分類（START/JTAS）プロトコルに基づく臨床手順 [C5, H1, H2]
- **ResourceAllocation** (ord=2): 救急リソース（人員・設備・ベッド数）の効率的配分に関する方針 [C6, H3, H4]
- **AdaptiveRefinement** (ord=1): 過去症例・フィードバックに基づく判断精度の改善仮説 [H5, H6, H7]
-/

namespace TestCoverage.S411

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s411_p01
  | s411_p02
  | s411_p03
  | s411_p04
  | s411_p05
  | s411_p06
  | s411_p07
  | s411_p08
  | s411_p09
  | s411_p10
  | s411_p11
  | s411_p12
  | s411_p13
  | s411_p14
  | s411_p15
  | s411_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s411_p01 => []
  | .s411_p02 => []
  | .s411_p03 => [.s411_p01, .s411_p02]
  | .s411_p04 => [.s411_p01]
  | .s411_p05 => [.s411_p02]
  | .s411_p06 => [.s411_p04, .s411_p05]
  | .s411_p07 => [.s411_p04]
  | .s411_p08 => [.s411_p05, .s411_p06]
  | .s411_p09 => [.s411_p07, .s411_p08]
  | .s411_p10 => [.s411_p07]
  | .s411_p11 => [.s411_p08]
  | .s411_p12 => [.s411_p10, .s411_p11]
  | .s411_p13 => [.s411_p10]
  | .s411_p14 => [.s411_p11]
  | .s411_p15 => [.s411_p12]
  | .s411_p16 => [.s411_p13, .s411_p14, .s411_p15]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 患者の生命維持に直結する絶対制約。いかなる判断も生命安全を下回ることはできない (ord=5) -/
  | LifeSafetyAbsolute
  /-- 医療倫理・インフォームドコンセント・守秘義務に関する規範的制約 (ord=4) -/
  | MedicalEthicsCompliance
  /-- トリアージ分類（START/JTAS）プロトコルに基づく臨床手順 (ord=3) -/
  | ClinicalProtocol
  /-- 救急リソース（人員・設備・ベッド数）の効率的配分に関する方針 (ord=2) -/
  | ResourceAllocation
  /-- 過去症例・フィードバックに基づく判断精度の改善仮説 (ord=1) -/
  | AdaptiveRefinement
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LifeSafetyAbsolute => 5
  | .MedicalEthicsCompliance => 4
  | .ClinicalProtocol => 3
  | .ResourceAllocation => 2
  | .AdaptiveRefinement => 1

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
  bottom := .AdaptiveRefinement
  nontrivial := ⟨.LifeSafetyAbsolute, .AdaptiveRefinement, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LifeSafetyAbsolute
  | .s411_p01 | .s411_p02 | .s411_p03 => .LifeSafetyAbsolute
  -- MedicalEthicsCompliance
  | .s411_p04 | .s411_p05 | .s411_p06 => .MedicalEthicsCompliance
  -- ClinicalProtocol
  | .s411_p07 | .s411_p08 | .s411_p09 => .ClinicalProtocol
  -- ResourceAllocation
  | .s411_p10 | .s411_p11 | .s411_p12 => .ResourceAllocation
  -- AdaptiveRefinement
  | .s411_p13 | .s411_p14 | .s411_p15 | .s411_p16 => .AdaptiveRefinement

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

end TestCoverage.S411
