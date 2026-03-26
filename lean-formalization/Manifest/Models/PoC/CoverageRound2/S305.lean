/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **SafetyConstraint** (ord=3): 人・家畜・禁止空域への衝突回避に関する安全制約 [C1, C2]
- **AgriPolicy** (ord=2): 農薬散布量・飛行経路・作業スケジュール管理方針 [C3, C4, H1, H2]
- **CropHypothesis** (ord=1): 作物成長状態・病害リスク推定に関する仮説 [H3, H4, H5]
-/

namespace TestCoverage.S305

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s305_p01
  | s305_p02
  | s305_p03
  | s305_p04
  | s305_p05
  | s305_p06
  | s305_p07
  | s305_p08
  | s305_p09
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s305_p01 => []
  | .s305_p02 => [.s305_p01]
  | .s305_p03 => [.s305_p01]
  | .s305_p04 => [.s305_p02]
  | .s305_p05 => [.s305_p03]
  | .s305_p06 => [.s305_p03]
  | .s305_p07 => [.s305_p04, .s305_p05]
  | .s305_p08 => [.s305_p06]
  | .s305_p09 => [.s305_p07, .s305_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人・家畜・禁止空域への衝突回避に関する安全制約 (ord=3) -/
  | SafetyConstraint
  /-- 農薬散布量・飛行経路・作業スケジュール管理方針 (ord=2) -/
  | AgriPolicy
  /-- 作物成長状態・病害リスク推定に関する仮説 (ord=1) -/
  | CropHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .SafetyConstraint => 3
  | .AgriPolicy => 2
  | .CropHypothesis => 1

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
  bottom := .CropHypothesis
  nontrivial := ⟨.SafetyConstraint, .CropHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- SafetyConstraint
  | .s305_p01 | .s305_p02 => .SafetyConstraint
  -- AgriPolicy
  | .s305_p03 | .s305_p04 | .s305_p05 => .AgriPolicy
  -- CropHypothesis
  | .s305_p06 | .s305_p07 | .s305_p08 | .s305_p09 => .CropHypothesis

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

end TestCoverage.S305
