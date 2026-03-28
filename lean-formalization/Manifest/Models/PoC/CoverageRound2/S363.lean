/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ServiceIntegrity** (ord=3): マルチモーダル交通サービスの継続性・利用者安全の不変条件 [C1, C2]
- **InteroperabilityPolicy** (ord=2): 交通事業者間データ共有・決済統合・API連携方針 [C3, C4, H1, H2]
- **OptimizationHypothesis** (ord=1): 経路最適化・需要予測・混雑緩和に関する推論仮説 [C5, H3, H4, H5]
-/

namespace TestCoverage.S363

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s363_p01
  | s363_p02
  | s363_p03
  | s363_p04
  | s363_p05
  | s363_p06
  | s363_p07
  | s363_p08
  | s363_p09
  | s363_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s363_p01 => []
  | .s363_p02 => [.s363_p01]
  | .s363_p03 => [.s363_p01]
  | .s363_p04 => [.s363_p02]
  | .s363_p05 => [.s363_p03, .s363_p04]
  | .s363_p06 => [.s363_p03]
  | .s363_p07 => [.s363_p04]
  | .s363_p08 => [.s363_p05, .s363_p06]
  | .s363_p09 => [.s363_p07]
  | .s363_p10 => [.s363_p08, .s363_p09]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- マルチモーダル交通サービスの継続性・利用者安全の不変条件 (ord=3) -/
  | ServiceIntegrity
  /-- 交通事業者間データ共有・決済統合・API連携方針 (ord=2) -/
  | InteroperabilityPolicy
  /-- 経路最適化・需要予測・混雑緩和に関する推論仮説 (ord=1) -/
  | OptimizationHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ServiceIntegrity => 3
  | .InteroperabilityPolicy => 2
  | .OptimizationHypothesis => 1

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
  bottom := .OptimizationHypothesis
  nontrivial := ⟨.ServiceIntegrity, .OptimizationHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ServiceIntegrity
  | .s363_p01 | .s363_p02 => .ServiceIntegrity
  -- InteroperabilityPolicy
  | .s363_p03 | .s363_p04 | .s363_p05 => .InteroperabilityPolicy
  -- OptimizationHypothesis
  | .s363_p06 | .s363_p07 | .s363_p08 | .s363_p09 | .s363_p10 => .OptimizationHypothesis

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

end TestCoverage.S363
