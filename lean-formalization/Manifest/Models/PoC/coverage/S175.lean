/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicsLaw** (ord=4): 流体力学の基本法則。変更不可 [C1, C2]
- **UrbanRegulation** (ord=3): 都市計画・建築基準法に基づく環境評価基準 [C3, H1]
- **SimulationDesign** (ord=2): シミュレーション手法の設計選択 [C4, H2, H3]
- **ValidationHypothesis** (ord=1): 検証精度に関する未検証の仮説 [C5, H4]
-/

namespace TestCoverage.S175

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s175_p01
  | s175_p02
  | s175_p03
  | s175_p04
  | s175_p05
  | s175_p06
  | s175_p07
  | s175_p08
  | s175_p09
  | s175_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s175_p01 => []
  | .s175_p02 => []
  | .s175_p03 => [.s175_p01]
  | .s175_p04 => [.s175_p01, .s175_p02]
  | .s175_p05 => [.s175_p03]
  | .s175_p06 => [.s175_p03, .s175_p04]
  | .s175_p07 => [.s175_p04]
  | .s175_p08 => [.s175_p05]
  | .s175_p09 => [.s175_p06, .s175_p07]
  | .s175_p10 => [.s175_p05, .s175_p06]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 流体力学の基本法則。変更不可 (ord=4) -/
  | PhysicsLaw
  /-- 都市計画・建築基準法に基づく環境評価基準 (ord=3) -/
  | UrbanRegulation
  /-- シミュレーション手法の設計選択 (ord=2) -/
  | SimulationDesign
  /-- 検証精度に関する未検証の仮説 (ord=1) -/
  | ValidationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicsLaw => 4
  | .UrbanRegulation => 3
  | .SimulationDesign => 2
  | .ValidationHypothesis => 1

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
  bottom := .ValidationHypothesis
  nontrivial := ⟨.PhysicsLaw, .ValidationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicsLaw
  | .s175_p01 | .s175_p02 => .PhysicsLaw
  -- UrbanRegulation
  | .s175_p03 | .s175_p04 => .UrbanRegulation
  -- SimulationDesign
  | .s175_p05 | .s175_p06 | .s175_p07 => .SimulationDesign
  -- ValidationHypothesis
  | .s175_p08 | .s175_p09 | .s175_p10 => .ValidationHypothesis

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

end TestCoverage.S175
