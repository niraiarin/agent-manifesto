/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AirspaceSafety** (ord=4): 航空法・飛行禁止区域の安全制約。違反は法的責任を伴う [C1, C2]
- **RegulatoryCompliance** (ord=3): 自治体規制・騒音制限。外部権威による制約 [C3, H1]
- **OperationalPolicy** (ord=2): 運用ポリシー。天候・バッテリー残量に基づく判断基準 [C4, C5, H2]
- **RouteOptimization** (ord=1): 配送効率の最適化。コスト・時間のトレードオフ [H3, H4]
- **AdaptiveHeuristic** (ord=0): 運用データから学習する経験的ヒューリスティック [H5]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s121_p01
  | s121_p02
  | s121_p03
  | s121_p04
  | s121_p05
  | s121_p06
  | s121_p07
  | s121_p08
  | s121_p09
  | s121_p10
  | s121_p11
  | s121_p12
  | s121_p13
  | s121_p14
  | s121_p15
  | s121_p16
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s121_p01 => []
  | .s121_p02 => []
  | .s121_p03 => []
  | .s121_p04 => [.s121_p01]
  | .s121_p05 => [.s121_p02]
  | .s121_p06 => [.s121_p01, .s121_p03]
  | .s121_p07 => [.s121_p04]
  | .s121_p08 => [.s121_p05]
  | .s121_p09 => [.s121_p04, .s121_p06]
  | .s121_p10 => [.s121_p07]
  | .s121_p11 => [.s121_p08, .s121_p09]
  | .s121_p12 => [.s121_p07]
  | .s121_p13 => [.s121_p10]
  | .s121_p14 => [.s121_p11]
  | .s121_p15 => [.s121_p12, .s121_p13]
  | .s121_p16 => [.s121_p02]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 航空法・飛行禁止区域の安全制約。違反は法的責任を伴う (ord=4) -/
  | AirspaceSafety
  /-- 自治体規制・騒音制限。外部権威による制約 (ord=3) -/
  | RegulatoryCompliance
  /-- 運用ポリシー。天候・バッテリー残量に基づく判断基準 (ord=2) -/
  | OperationalPolicy
  /-- 配送効率の最適化。コスト・時間のトレードオフ (ord=1) -/
  | RouteOptimization
  /-- 運用データから学習する経験的ヒューリスティック (ord=0) -/
  | AdaptiveHeuristic
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AirspaceSafety => 4
  | .RegulatoryCompliance => 3
  | .OperationalPolicy => 2
  | .RouteOptimization => 1
  | .AdaptiveHeuristic => 0

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
  bottom := .AdaptiveHeuristic
  nontrivial := ⟨.AirspaceSafety, .AdaptiveHeuristic, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AirspaceSafety
  | .s121_p01 | .s121_p02 | .s121_p03 => .AirspaceSafety
  -- RegulatoryCompliance
  | .s121_p04 | .s121_p05 | .s121_p06 => .RegulatoryCompliance
  -- OperationalPolicy
  | .s121_p07 | .s121_p08 | .s121_p09 | .s121_p16 => .OperationalPolicy
  -- RouteOptimization
  | .s121_p10 | .s121_p11 | .s121_p12 => .RouteOptimization
  -- AdaptiveHeuristic
  | .s121_p13 | .s121_p14 | .s121_p15 => .AdaptiveHeuristic

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

end Manifest.Models
