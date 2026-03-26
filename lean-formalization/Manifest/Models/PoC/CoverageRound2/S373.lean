/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **MissionCriticalSafety** (ord=3): 宇宙機・乗員の安全確保に関する絶対不変条件 [C1, C2]
- **TrackingOperationsPolicy** (ord=2): 観測スケジュール・警報発令・軌道修正指令の方針 [C3, C4, H1]
- **OrbitPropagationHypothesis** (ord=1): 軌道伝播モデル・大気抵抗推定に関する予測仮説 [C5, C6, H2, H3, H4, H5]
-/

namespace TestCoverage.S373

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s373_p01
  | s373_p02
  | s373_p03
  | s373_p04
  | s373_p05
  | s373_p06
  | s373_p07
  | s373_p08
  | s373_p09
  | s373_p10
  | s373_p11
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s373_p01 => []
  | .s373_p02 => []
  | .s373_p03 => [.s373_p01, .s373_p02]
  | .s373_p04 => [.s373_p01]
  | .s373_p05 => [.s373_p02]
  | .s373_p06 => [.s373_p03, .s373_p04]
  | .s373_p07 => [.s373_p04]
  | .s373_p08 => [.s373_p05]
  | .s373_p09 => [.s373_p06]
  | .s373_p10 => [.s373_p07, .s373_p08]
  | .s373_p11 => [.s373_p09, .s373_p10]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 宇宙機・乗員の安全確保に関する絶対不変条件 (ord=3) -/
  | MissionCriticalSafety
  /-- 観測スケジュール・警報発令・軌道修正指令の方針 (ord=2) -/
  | TrackingOperationsPolicy
  /-- 軌道伝播モデル・大気抵抗推定に関する予測仮説 (ord=1) -/
  | OrbitPropagationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .MissionCriticalSafety => 3
  | .TrackingOperationsPolicy => 2
  | .OrbitPropagationHypothesis => 1

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
  bottom := .OrbitPropagationHypothesis
  nontrivial := ⟨.MissionCriticalSafety, .OrbitPropagationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- MissionCriticalSafety
  | .s373_p01 | .s373_p02 | .s373_p03 => .MissionCriticalSafety
  -- TrackingOperationsPolicy
  | .s373_p04 | .s373_p05 | .s373_p06 => .TrackingOperationsPolicy
  -- OrbitPropagationHypothesis
  | .s373_p07 | .s373_p08 | .s373_p09 | .s373_p10 | .s373_p11 => .OrbitPropagationHypothesis

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

end TestCoverage.S373
