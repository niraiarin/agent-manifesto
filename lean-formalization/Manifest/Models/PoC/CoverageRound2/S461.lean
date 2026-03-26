/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AnimalWelfareInvariant** (ord=3): 動物の生命・福祉を守る最上位制約。危険な診断推奨の絶対排除 [C1, C2]
- **VeterinaryCompliance** (ord=2): 獣医師法・医薬品規制に基づく診断補助ガイドライン準拠 [C3, C4, H1]
- **HealthPredictionHypothesis** (ord=1): バイタルデータ・行動パターンから疾患リスクを推定する仮説層 [H2, H3, H4, H5, H6]
-/

namespace TestCoverage.S461

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s461_p01
  | s461_p02
  | s461_p03
  | s461_p04
  | s461_p05
  | s461_p06
  | s461_p07
  | s461_p08
  | s461_p09
  | s461_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s461_p01 => []
  | .s461_p02 => [.s461_p01]
  | .s461_p03 => [.s461_p01]
  | .s461_p04 => [.s461_p02]
  | .s461_p05 => [.s461_p03, .s461_p04]
  | .s461_p06 => [.s461_p03]
  | .s461_p07 => [.s461_p04]
  | .s461_p08 => [.s461_p06]
  | .s461_p09 => [.s461_p07]
  | .s461_p10 => [.s461_p08, .s461_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 動物の生命・福祉を守る最上位制約。危険な診断推奨の絶対排除 (ord=3) -/
  | AnimalWelfareInvariant
  /-- 獣医師法・医薬品規制に基づく診断補助ガイドライン準拠 (ord=2) -/
  | VeterinaryCompliance
  /-- バイタルデータ・行動パターンから疾患リスクを推定する仮説層 (ord=1) -/
  | HealthPredictionHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AnimalWelfareInvariant => 3
  | .VeterinaryCompliance => 2
  | .HealthPredictionHypothesis => 1

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
  bottom := .HealthPredictionHypothesis
  nontrivial := ⟨.AnimalWelfareInvariant, .HealthPredictionHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AnimalWelfareInvariant
  | .s461_p01 | .s461_p02 => .AnimalWelfareInvariant
  -- VeterinaryCompliance
  | .s461_p03 | .s461_p04 | .s461_p05 => .VeterinaryCompliance
  -- HealthPredictionHypothesis
  | .s461_p06 | .s461_p07 | .s461_p08 | .s461_p09 | .s461_p10 => .HealthPredictionHypothesis

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

end TestCoverage.S461
