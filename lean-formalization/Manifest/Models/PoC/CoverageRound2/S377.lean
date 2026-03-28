/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **DownstreamSafetyInvariant** (ord=4): 下流住民・インフラの浸水被害防止に関する絶対不変条件 [C1, C2]
- **DamOperationRegulation** (ord=3): 河川法・操作規則・放流量制限の法的要件 [C3, C4]
- **FloodDischargePolicy** (ord=2): 予備放流・段階的増量・警報発令タイミングの方針 [C5, H1, H2]
- **HydrologicalModelHypothesis** (ord=1): 流入量予測・貯水位変化・下流河道伝播の推論仮説 [C6, H3, H4, H5]
-/

namespace TestCoverage.S377

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s377_p01
  | s377_p02
  | s377_p03
  | s377_p04
  | s377_p05
  | s377_p06
  | s377_p07
  | s377_p08
  | s377_p09
  | s377_p10
  | s377_p11
  | s377_p12
  | s377_p13
  | s377_p14
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s377_p01 => []
  | .s377_p02 => []
  | .s377_p03 => [.s377_p01, .s377_p02]
  | .s377_p04 => [.s377_p01]
  | .s377_p05 => [.s377_p02]
  | .s377_p06 => [.s377_p03, .s377_p04]
  | .s377_p07 => [.s377_p04]
  | .s377_p08 => [.s377_p05]
  | .s377_p09 => [.s377_p06, .s377_p07]
  | .s377_p10 => [.s377_p07]
  | .s377_p11 => [.s377_p08]
  | .s377_p12 => [.s377_p09, .s377_p10]
  | .s377_p13 => [.s377_p10, .s377_p11]
  | .s377_p14 => [.s377_p12, .s377_p13]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 下流住民・インフラの浸水被害防止に関する絶対不変条件 (ord=4) -/
  | DownstreamSafetyInvariant
  /-- 河川法・操作規則・放流量制限の法的要件 (ord=3) -/
  | DamOperationRegulation
  /-- 予備放流・段階的増量・警報発令タイミングの方針 (ord=2) -/
  | FloodDischargePolicy
  /-- 流入量予測・貯水位変化・下流河道伝播の推論仮説 (ord=1) -/
  | HydrologicalModelHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .DownstreamSafetyInvariant => 4
  | .DamOperationRegulation => 3
  | .FloodDischargePolicy => 2
  | .HydrologicalModelHypothesis => 1

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
  bottom := .HydrologicalModelHypothesis
  nontrivial := ⟨.DownstreamSafetyInvariant, .HydrologicalModelHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- DownstreamSafetyInvariant
  | .s377_p01 | .s377_p02 | .s377_p03 => .DownstreamSafetyInvariant
  -- DamOperationRegulation
  | .s377_p04 | .s377_p05 | .s377_p06 => .DamOperationRegulation
  -- FloodDischargePolicy
  | .s377_p07 | .s377_p08 | .s377_p09 => .FloodDischargePolicy
  -- HydrologicalModelHypothesis
  | .s377_p10 | .s377_p11 | .s377_p12 | .s377_p13 | .s377_p14 => .HydrologicalModelHypothesis

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

end TestCoverage.S377
