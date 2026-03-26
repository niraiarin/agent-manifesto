/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ProductSafetyInvariant** (ord=4): 航空・自動車部品の強度基準違反ゼロの絶対要件 [C1, C2]
- **QualityStandardPolicy** (ord=3): ISO9001・IATF16949・JIS規格への適合方針 [C3, C4]
- **ProcessParameterModel** (ord=2): 溶湯温度・充填速度・冷却速度の欠陥発生メカニズム [H1, H2, H3]
- **DefectPredictionHypothesis** (ord=1): 気泡・収縮巣・ミスランの発生確率に関する予測仮説 [H4, H5, H6, H7]
-/

namespace TestCoverage.S484

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s484_p01
  | s484_p02
  | s484_p03
  | s484_p04
  | s484_p05
  | s484_p06
  | s484_p07
  | s484_p08
  | s484_p09
  | s484_p10
  | s484_p11
  | s484_p12
  | s484_p13
  | s484_p14
  | s484_p15
  | s484_p16
  | s484_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s484_p01 => []
  | .s484_p02 => []
  | .s484_p03 => [.s484_p01, .s484_p02]
  | .s484_p04 => [.s484_p01]
  | .s484_p05 => [.s484_p02]
  | .s484_p06 => [.s484_p04, .s484_p05]
  | .s484_p07 => [.s484_p04]
  | .s484_p08 => [.s484_p05]
  | .s484_p09 => [.s484_p06, .s484_p07]
  | .s484_p10 => [.s484_p07, .s484_p08, .s484_p09]
  | .s484_p11 => [.s484_p07]
  | .s484_p12 => [.s484_p08]
  | .s484_p13 => [.s484_p09, .s484_p11]
  | .s484_p14 => [.s484_p10, .s484_p12]
  | .s484_p15 => [.s484_p11, .s484_p12]
  | .s484_p16 => [.s484_p13, .s484_p14]
  | .s484_p17 => [.s484_p15, .s484_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 航空・自動車部品の強度基準違反ゼロの絶対要件 (ord=4) -/
  | ProductSafetyInvariant
  /-- ISO9001・IATF16949・JIS規格への適合方針 (ord=3) -/
  | QualityStandardPolicy
  /-- 溶湯温度・充填速度・冷却速度の欠陥発生メカニズム (ord=2) -/
  | ProcessParameterModel
  /-- 気泡・収縮巣・ミスランの発生確率に関する予測仮説 (ord=1) -/
  | DefectPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ProductSafetyInvariant => 4
  | .QualityStandardPolicy => 3
  | .ProcessParameterModel => 2
  | .DefectPredictionHypothesis => 1

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
  bottom := .DefectPredictionHypothesis
  nontrivial := ⟨.ProductSafetyInvariant, .DefectPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ProductSafetyInvariant
  | .s484_p01 | .s484_p02 | .s484_p03 => .ProductSafetyInvariant
  -- QualityStandardPolicy
  | .s484_p04 | .s484_p05 | .s484_p06 => .QualityStandardPolicy
  -- ProcessParameterModel
  | .s484_p07 | .s484_p08 | .s484_p09 | .s484_p10 => .ProcessParameterModel
  -- DefectPredictionHypothesis
  | .s484_p11 | .s484_p12 | .s484_p13 | .s484_p14 | .s484_p15 | .s484_p16 | .s484_p17 => .DefectPredictionHypothesis

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

end TestCoverage.S484
