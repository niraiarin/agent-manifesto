/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ChildProtection** (ord=5): 児童の権利・福祉に関する不可侵の安全制約 [C1, C2]
- **ClinicalStandard** (ord=4): 医学的根拠に基づく臨床基準 [C3, H1]
- **EthicalGuideline** (ord=3): スクリーニングの倫理的ガイドライン [C4, C5]
- **AssessmentDesign** (ord=2): 評価手法の設計選択 [C6, H2, H3]
- **DataPipeline** (ord=1): データ処理・分析パイプラインの技術選択 [H4, H5]
- **ExploratoryHypothesis** (ord=0): 検証待ちの探索的仮説 [H6]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s122_p01
  | s122_p02
  | s122_p03
  | s122_p04
  | s122_p05
  | s122_p06
  | s122_p07
  | s122_p08
  | s122_p09
  | s122_p10
  | s122_p11
  | s122_p12
  | s122_p13
  | s122_p14
  | s122_p15
  | s122_p16
  | s122_p17
  | s122_p18
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s122_p01 => []
  | .s122_p02 => []
  | .s122_p03 => []
  | .s122_p04 => [.s122_p01]
  | .s122_p05 => [.s122_p01, .s122_p02]
  | .s122_p06 => [.s122_p04]
  | .s122_p07 => [.s122_p01]
  | .s122_p08 => [.s122_p04, .s122_p05]
  | .s122_p09 => [.s122_p06]
  | .s122_p10 => [.s122_p07]
  | .s122_p11 => [.s122_p14]
  | .s122_p12 => [.s122_p06, .s122_p08]
  | .s122_p13 => [.s122_p09]
  | .s122_p14 => [.s122_p05]
  | .s122_p15 => [.s122_p10, .s122_p12]
  | .s122_p16 => [.s122_p13]
  | .s122_p17 => [.s122_p14, .s122_p15]
  | .s122_p18 => [.s122_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 児童の権利・福祉に関する不可侵の安全制約 (ord=5) -/
  | ChildProtection
  /-- 医学的根拠に基づく臨床基準 (ord=4) -/
  | ClinicalStandard
  /-- スクリーニングの倫理的ガイドライン (ord=3) -/
  | EthicalGuideline
  /-- 評価手法の設計選択 (ord=2) -/
  | AssessmentDesign
  /-- データ処理・分析パイプラインの技術選択 (ord=1) -/
  | DataPipeline
  /-- 検証待ちの探索的仮説 (ord=0) -/
  | ExploratoryHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ChildProtection => 5
  | .ClinicalStandard => 4
  | .EthicalGuideline => 3
  | .AssessmentDesign => 2
  | .DataPipeline => 1
  | .ExploratoryHypothesis => 0

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
  bottom := .ExploratoryHypothesis
  nontrivial := ⟨.ChildProtection, .ExploratoryHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ChildProtection
  | .s122_p01 | .s122_p02 | .s122_p03 => .ChildProtection
  -- ClinicalStandard
  | .s122_p04 | .s122_p05 => .ClinicalStandard
  -- EthicalGuideline
  | .s122_p06 | .s122_p07 | .s122_p08 | .s122_p11 | .s122_p14 => .EthicalGuideline
  -- AssessmentDesign
  | .s122_p09 | .s122_p10 | .s122_p12 => .AssessmentDesign
  -- DataPipeline
  | .s122_p13 | .s122_p15 => .DataPipeline
  -- ExploratoryHypothesis
  | .s122_p16 | .s122_p17 | .s122_p18 => .ExploratoryHypothesis

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
