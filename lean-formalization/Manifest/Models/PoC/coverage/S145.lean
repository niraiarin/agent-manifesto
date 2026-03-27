/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **TrafficSafety** (ord=2): 道路交通の安全に直結する制約。故障時の安全確保が最優先 [C1, C2, C3]
- **MaintenancePolicy** (ord=1): 保守運用のポリシー。予算・人員に応じて調整可能 [C4, C5, H1, H2]
- **PredictiveHypothesis** (ord=0): 故障予測モデルの仮説。実運用データで検証が必要 [H3, H4]
-/

namespace TestCoverage.S145

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s145_p01
  | s145_p02
  | s145_p03
  | s145_p04
  | s145_p05
  | s145_p06
  | s145_p07
  | s145_p08
  | s145_p09
  | s145_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s145_p01 => []
  | .s145_p02 => []
  | .s145_p03 => []
  | .s145_p04 => [.s145_p01]
  | .s145_p05 => [.s145_p02]
  | .s145_p06 => [.s145_p01, .s145_p03]
  | .s145_p07 => [.s145_p04]
  | .s145_p08 => [.s145_p05]
  | .s145_p09 => [.s145_p04, .s145_p06]
  | .s145_p10 => [.s145_p07, .s145_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 道路交通の安全に直結する制約。故障時の安全確保が最優先 (ord=2) -/
  | TrafficSafety
  /-- 保守運用のポリシー。予算・人員に応じて調整可能 (ord=1) -/
  | MaintenancePolicy
  /-- 故障予測モデルの仮説。実運用データで検証が必要 (ord=0) -/
  | PredictiveHypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .TrafficSafety => 2
  | .MaintenancePolicy => 1
  | .PredictiveHypothesis => 0

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
  bottom := .PredictiveHypothesis
  nontrivial := ⟨.TrafficSafety, .PredictiveHypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- TrafficSafety
  | .s145_p01 | .s145_p02 | .s145_p03 => .TrafficSafety
  -- MaintenancePolicy
  | .s145_p04 | .s145_p05 | .s145_p06 => .MaintenancePolicy
  -- PredictiveHypothesis
  | .s145_p07 | .s145_p08 | .s145_p09 | .s145_p10 => .PredictiveHypothesis

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

end TestCoverage.S145
