/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **PhysicalSecurityInvariant** (ord=5): エッジノードの物理的セキュリティ・耐障害性・電源冗長性の絶対不変条件 [C1]
- **DataSovereigntyPolicy** (ord=4): データ主権・プライバシー規制・国境越えデータ転送制約 [C2, C3]
- **LatencyQoSPolicy** (ord=3): レイテンシSLA・帯域保証・QoS優先度管理の運用方針 [C4, H1]
- **ResourceAllocationPolicy** (ord=2): CPU・メモリ・ストレージの動的割当・スケーリング戦略 [C5, H2, H3]
- **WorkloadPlacementHypothesis** (ord=1): ワークロード配置最適化・キャッシュ効率・移行コストに関する仮説 [H4, H5]
-/

namespace TestCoverage.S443

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s443_p01
  | s443_p02
  | s443_p03
  | s443_p04
  | s443_p05
  | s443_p06
  | s443_p07
  | s443_p08
  | s443_p09
  | s443_p10
  | s443_p11
  | s443_p12
  | s443_p13
  | s443_p14
  | s443_p15
  | s443_p16
  | s443_p17
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s443_p01 => []
  | .s443_p02 => [.s443_p01]
  | .s443_p03 => [.s443_p01]
  | .s443_p04 => [.s443_p02, .s443_p03]
  | .s443_p05 => [.s443_p02]
  | .s443_p06 => [.s443_p04]
  | .s443_p07 => [.s443_p05, .s443_p06]
  | .s443_p08 => [.s443_p05]
  | .s443_p09 => [.s443_p06]
  | .s443_p10 => [.s443_p07, .s443_p08]
  | .s443_p11 => [.s443_p09, .s443_p10]
  | .s443_p12 => [.s443_p08]
  | .s443_p13 => [.s443_p09]
  | .s443_p14 => [.s443_p11, .s443_p12]
  | .s443_p15 => [.s443_p13]
  | .s443_p16 => [.s443_p14, .s443_p15]
  | .s443_p17 => [.s443_p16]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- エッジノードの物理的セキュリティ・耐障害性・電源冗長性の絶対不変条件 (ord=5) -/
  | PhysicalSecurityInvariant
  /-- データ主権・プライバシー規制・国境越えデータ転送制約 (ord=4) -/
  | DataSovereigntyPolicy
  /-- レイテンシSLA・帯域保証・QoS優先度管理の運用方針 (ord=3) -/
  | LatencyQoSPolicy
  /-- CPU・メモリ・ストレージの動的割当・スケーリング戦略 (ord=2) -/
  | ResourceAllocationPolicy
  /-- ワークロード配置最適化・キャッシュ効率・移行コストに関する仮説 (ord=1) -/
  | WorkloadPlacementHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .PhysicalSecurityInvariant => 5
  | .DataSovereigntyPolicy => 4
  | .LatencyQoSPolicy => 3
  | .ResourceAllocationPolicy => 2
  | .WorkloadPlacementHypothesis => 1

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
  bottom := .WorkloadPlacementHypothesis
  nontrivial := ⟨.PhysicalSecurityInvariant, .WorkloadPlacementHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- PhysicalSecurityInvariant
  | .s443_p01 => .PhysicalSecurityInvariant
  -- DataSovereigntyPolicy
  | .s443_p02 | .s443_p03 | .s443_p04 => .DataSovereigntyPolicy
  -- LatencyQoSPolicy
  | .s443_p05 | .s443_p06 | .s443_p07 => .LatencyQoSPolicy
  -- ResourceAllocationPolicy
  | .s443_p08 | .s443_p09 | .s443_p10 | .s443_p11 => .ResourceAllocationPolicy
  -- WorkloadPlacementHypothesis
  | .s443_p12 | .s443_p13 | .s443_p14 | .s443_p15 | .s443_p16 | .s443_p17 => .WorkloadPlacementHypothesis

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

end TestCoverage.S443
