/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **LegalFramework** (ord=4): 国際法・文化財保護法に基づく法的義務。変更不可 [C1, C2]
- **ProvenanceStandard** (ord=3): 来歴調査の業界標準。学術的合意に基づく [C3, H1]
- **InvestigativeMethod** (ord=2): 調査手法の設計選択。技術の進歩で更新可能 [C4, C5, H2]
- **DetectionAlgorithm** (ord=1): 画像照合・パターン認識のアルゴリズム設計 [C6, H3, H4]
- **MatchHypothesis** (ord=0): 照合精度に関する未検証仮説 [H5]
-/

namespace TestCoverage.S184

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s184_p01
  | s184_p02
  | s184_p03
  | s184_p04
  | s184_p05
  | s184_p06
  | s184_p07
  | s184_p08
  | s184_p09
  | s184_p10
  | s184_p11
  | s184_p12
  | s184_p13
  | s184_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s184_p01 => []
  | .s184_p02 => []
  | .s184_p03 => [.s184_p01]
  | .s184_p04 => [.s184_p01, .s184_p02]
  | .s184_p05 => [.s184_p03]
  | .s184_p06 => [.s184_p03]
  | .s184_p07 => [.s184_p03, .s184_p04]
  | .s184_p08 => [.s184_p05]
  | .s184_p09 => [.s184_p06]
  | .s184_p10 => [.s184_p05, .s184_p07]
  | .s184_p11 => [.s184_p06]
  | .s184_p12 => [.s184_p08]
  | .s184_p13 => [.s184_p09, .s184_p10]
  | .s184_p14 => [.s184_p11]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 国際法・文化財保護法に基づく法的義務。変更不可 (ord=4) -/
  | LegalFramework
  /-- 来歴調査の業界標準。学術的合意に基づく (ord=3) -/
  | ProvenanceStandard
  /-- 調査手法の設計選択。技術の進歩で更新可能 (ord=2) -/
  | InvestigativeMethod
  /-- 画像照合・パターン認識のアルゴリズム設計 (ord=1) -/
  | DetectionAlgorithm
  /-- 照合精度に関する未検証仮説 (ord=0) -/
  | MatchHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .LegalFramework => 4
  | .ProvenanceStandard => 3
  | .InvestigativeMethod => 2
  | .DetectionAlgorithm => 1
  | .MatchHypothesis => 0

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
  bottom := .MatchHypothesis
  nontrivial := ⟨.LegalFramework, .MatchHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- LegalFramework
  | .s184_p01 | .s184_p02 => .LegalFramework
  -- ProvenanceStandard
  | .s184_p03 | .s184_p04 => .ProvenanceStandard
  -- InvestigativeMethod
  | .s184_p05 | .s184_p06 | .s184_p07 => .InvestigativeMethod
  -- DetectionAlgorithm
  | .s184_p08 | .s184_p09 | .s184_p10 | .s184_p11 => .DetectionAlgorithm
  -- MatchHypothesis
  | .s184_p12 | .s184_p13 | .s184_p14 => .MatchHypothesis

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

end TestCoverage.S184
