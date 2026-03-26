/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **MedicalSafety** (ord=3): 医学的安全基準。睡眠障害の見落とし防止・医療機関への適切な誘導 [C1, C2]
- **SleepScience** (ord=2): 睡眠科学のエビデンスに基づく改善手法 [C3, C4, H1, H2]
- **PersonalizationHypothesis** (ord=1): 個人最適化アルゴリズムの未検証仮説 [C5, H3, H4, H5]
-/

namespace TestCoverage.S107

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s107_p01
  | s107_p02
  | s107_p03
  | s107_p04
  | s107_p05
  | s107_p06
  | s107_p07
  | s107_p08
  | s107_p09
  | s107_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s107_p01 => []
  | .s107_p02 => []
  | .s107_p03 => []
  | .s107_p04 => [.s107_p01]
  | .s107_p05 => [.s107_p02]
  | .s107_p06 => [.s107_p01, .s107_p03]
  | .s107_p07 => [.s107_p04]
  | .s107_p08 => [.s107_p05]
  | .s107_p09 => [.s107_p04, .s107_p06]
  | .s107_p10 => [.s107_p07, .s107_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 医学的安全基準。睡眠障害の見落とし防止・医療機関への適切な誘導 (ord=3) -/
  | MedicalSafety
  /-- 睡眠科学のエビデンスに基づく改善手法 (ord=2) -/
  | SleepScience
  /-- 個人最適化アルゴリズムの未検証仮説 (ord=1) -/
  | PersonalizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .MedicalSafety => 3
  | .SleepScience => 2
  | .PersonalizationHypothesis => 1

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
  bottom := .PersonalizationHypothesis
  nontrivial := ⟨.MedicalSafety, .PersonalizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- MedicalSafety
  | .s107_p01 | .s107_p02 | .s107_p03 => .MedicalSafety
  -- SleepScience
  | .s107_p04 | .s107_p05 | .s107_p06 => .SleepScience
  -- PersonalizationHypothesis
  | .s107_p07 | .s107_p08 | .s107_p09 | .s107_p10 => .PersonalizationHypothesis

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

end TestCoverage.S107
