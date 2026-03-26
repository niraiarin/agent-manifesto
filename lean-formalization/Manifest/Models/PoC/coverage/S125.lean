/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AcademicStandard** (ord=4): 考古学の学術的基準・分類体系。学界の合意に基づく [C1, C2]
- **ProvenanceIntegrity** (ord=3): 出土記録・来歴の完全性要件 [C3, C4]
- **ClassificationMethod** (ord=2): 分類手法の設計選択。技術的妥当性に基づく [C5, H1, H2]
- **FeatureExtraction** (ord=1): 特徴抽出の技術的選択。精度と効率のトレードオフ [C6, H3, H4]
- **InterpretiveHypothesis** (ord=0): 解釈的仮説。専門家による検証が必要 [H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s125_p01
  | s125_p02
  | s125_p03
  | s125_p04
  | s125_p05
  | s125_p06
  | s125_p07
  | s125_p08
  | s125_p09
  | s125_p10
  | s125_p11
  | s125_p12
  | s125_p13
  | s125_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s125_p01 => []
  | .s125_p02 => []
  | .s125_p03 => [.s125_p01]
  | .s125_p04 => [.s125_p01, .s125_p02]
  | .s125_p05 => [.s125_p03]
  | .s125_p06 => [.s125_p04]
  | .s125_p07 => [.s125_p03, .s125_p04]
  | .s125_p08 => [.s125_p05]
  | .s125_p09 => [.s125_p06]
  | .s125_p10 => [.s125_p05, .s125_p07]
  | .s125_p11 => [.s125_p08]
  | .s125_p12 => [.s125_p09]
  | .s125_p13 => [.s125_p10, .s125_p11]
  | .s125_p14 => [.s125_p02]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 考古学の学術的基準・分類体系。学界の合意に基づく (ord=4) -/
  | AcademicStandard
  /-- 出土記録・来歴の完全性要件 (ord=3) -/
  | ProvenanceIntegrity
  /-- 分類手法の設計選択。技術的妥当性に基づく (ord=2) -/
  | ClassificationMethod
  /-- 特徴抽出の技術的選択。精度と効率のトレードオフ (ord=1) -/
  | FeatureExtraction
  /-- 解釈的仮説。専門家による検証が必要 (ord=0) -/
  | InterpretiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AcademicStandard => 4
  | .ProvenanceIntegrity => 3
  | .ClassificationMethod => 2
  | .FeatureExtraction => 1
  | .InterpretiveHypothesis => 0

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
  bottom := .InterpretiveHypothesis
  nontrivial := ⟨.AcademicStandard, .InterpretiveHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AcademicStandard
  | .s125_p01 | .s125_p02 => .AcademicStandard
  -- ProvenanceIntegrity
  | .s125_p03 | .s125_p04 | .s125_p14 => .ProvenanceIntegrity
  -- ClassificationMethod
  | .s125_p05 | .s125_p06 | .s125_p07 => .ClassificationMethod
  -- FeatureExtraction
  | .s125_p08 | .s125_p09 | .s125_p10 => .FeatureExtraction
  -- InterpretiveHypothesis
  | .s125_p11 | .s125_p12 | .s125_p13 => .InterpretiveHypothesis

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
