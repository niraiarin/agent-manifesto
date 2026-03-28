/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **EnvironmentalComplianceInvariant** (ord=3): 水質汚濁防止法・排水基準値遵守・行政報告の絶対条件 [C1, C2, C3]
- **TreatmentProcessPolicy** (ord=2): pH調整・凝集沈殿・活性汚泥処理の運転管理ポリシー [C4, C5, H1]
- **ProcessOptimizationHypothesis** (ord=1): センサーデータからの処理効率予測と薬品投入最適化仮説 [H2, H3, H4]
-/

namespace TestCoverage.S477

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s477_p01
  | s477_p02
  | s477_p03
  | s477_p04
  | s477_p05
  | s477_p06
  | s477_p07
  | s477_p08
  | s477_p09
  | s477_p10
  | s477_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s477_p01 => []
  | .s477_p02 => []
  | .s477_p03 => [.s477_p01, .s477_p02]
  | .s477_p04 => [.s477_p01]
  | .s477_p05 => [.s477_p02]
  | .s477_p06 => [.s477_p03, .s477_p04]
  | .s477_p07 => [.s477_p04]
  | .s477_p08 => [.s477_p05, .s477_p06]
  | .s477_p09 => [.s477_p07, .s477_p08]
  | .s477_p10 => [.s477_p05, .s477_p06]
  | .s477_p11 => [.s477_p08, .s477_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 水質汚濁防止法・排水基準値遵守・行政報告の絶対条件 (ord=3) -/
  | EnvironmentalComplianceInvariant
  /-- pH調整・凝集沈殿・活性汚泥処理の運転管理ポリシー (ord=2) -/
  | TreatmentProcessPolicy
  /-- センサーデータからの処理効率予測と薬品投入最適化仮説 (ord=1) -/
  | ProcessOptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .EnvironmentalComplianceInvariant => 3
  | .TreatmentProcessPolicy => 2
  | .ProcessOptimizationHypothesis => 1

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
  bottom := .ProcessOptimizationHypothesis
  nontrivial := ⟨.EnvironmentalComplianceInvariant, .ProcessOptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- EnvironmentalComplianceInvariant
  | .s477_p01 | .s477_p02 | .s477_p03 => .EnvironmentalComplianceInvariant
  -- TreatmentProcessPolicy
  | .s477_p04 | .s477_p05 | .s477_p06 | .s477_p10 => .TreatmentProcessPolicy
  -- ProcessOptimizationHypothesis
  | .s477_p07 | .s477_p08 | .s477_p09 | .s477_p11 => .ProcessOptimizationHypothesis

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

end TestCoverage.S477
