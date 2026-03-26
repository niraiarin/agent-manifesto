/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BioethicsConstraint** (ord=6): 生命倫理・個人情報保護に関する不変制約 [C1]
- **ScientificBasis** (ord=5): 微生物学・ゲノム科学の確立された知見 [C2, H1]
- **ClinicalEvidence** (ord=4): 臨床研究で裏付けられたエビデンス [C3, H2]
- **AnalysisPipeline** (ord=3): 解析パイプラインの設計選択 [C4, H3]
- **InterpretationModel** (ord=2): 解析結果の解釈モデル。データに基づく調整可能 [H4, H5]
- **ClinicalHypothesis** (ord=1): 臨床応用に関する未検証の仮説 [C5, H6]
-/

namespace TestCoverage.S174

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s174_p01
  | s174_p02
  | s174_p03
  | s174_p04
  | s174_p05
  | s174_p06
  | s174_p07
  | s174_p08
  | s174_p09
  | s174_p10
  | s174_p11
  | s174_p12
  | s174_p13
  | s174_p14
  | s174_p15
  | s174_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s174_p01 => []
  | .s174_p02 => [.s174_p01]
  | .s174_p03 => [.s174_p01]
  | .s174_p04 => [.s174_p02]
  | .s174_p05 => [.s174_p02, .s174_p03]
  | .s174_p06 => [.s174_p03]
  | .s174_p07 => [.s174_p04]
  | .s174_p08 => [.s174_p05]
  | .s174_p09 => [.s174_p04, .s174_p06]
  | .s174_p10 => [.s174_p07]
  | .s174_p11 => [.s174_p08]
  | .s174_p12 => [.s174_p07, .s174_p09]
  | .s174_p13 => [.s174_p10]
  | .s174_p14 => [.s174_p11]
  | .s174_p15 => [.s174_p12]
  | .s174_p16 => [.s174_p10, .s174_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 生命倫理・個人情報保護に関する不変制約 (ord=6) -/
  | BioethicsConstraint
  /-- 微生物学・ゲノム科学の確立された知見 (ord=5) -/
  | ScientificBasis
  /-- 臨床研究で裏付けられたエビデンス (ord=4) -/
  | ClinicalEvidence
  /-- 解析パイプラインの設計選択 (ord=3) -/
  | AnalysisPipeline
  /-- 解析結果の解釈モデル。データに基づく調整可能 (ord=2) -/
  | InterpretationModel
  /-- 臨床応用に関する未検証の仮説 (ord=1) -/
  | ClinicalHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BioethicsConstraint => 6
  | .ScientificBasis => 5
  | .ClinicalEvidence => 4
  | .AnalysisPipeline => 3
  | .InterpretationModel => 2
  | .ClinicalHypothesis => 1

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
  bottom := .ClinicalHypothesis
  nontrivial := ⟨.BioethicsConstraint, .ClinicalHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BioethicsConstraint
  | .s174_p01 => .BioethicsConstraint
  -- ScientificBasis
  | .s174_p02 | .s174_p03 => .ScientificBasis
  -- ClinicalEvidence
  | .s174_p04 | .s174_p05 | .s174_p06 => .ClinicalEvidence
  -- AnalysisPipeline
  | .s174_p07 | .s174_p08 | .s174_p09 => .AnalysisPipeline
  -- InterpretationModel
  | .s174_p10 | .s174_p11 | .s174_p12 => .InterpretationModel
  -- ClinicalHypothesis
  | .s174_p13 | .s174_p14 | .s174_p15 | .s174_p16 => .ClinicalHypothesis

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

end TestCoverage.S174
