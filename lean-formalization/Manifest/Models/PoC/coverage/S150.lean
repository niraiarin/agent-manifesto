/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **BusinessConstraint** (ord=2): 事業運営の不変制約。法規制・契約条件 [C1, C2]
- **OperationalRule** (ord=1): 補充オペレーションの運用ルール。効率に応じて調整可能 [C3, C4, H1, H2]
- **DemandForecast** (ord=0): 需要予測に関する仮説。販売データで継続的に検証 [H3, H4]
-/

namespace TestCoverage.S150

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | s150_p01
  | s150_p02
  | s150_p03
  | s150_p04
  | s150_p05
  | s150_p06
  | s150_p07
  | s150_p08
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .s150_p01 => []
  | .s150_p02 => []
  | .s150_p03 => [.s150_p01]
  | .s150_p04 => [.s150_p01, .s150_p02]
  | .s150_p05 => [.s150_p02]
  | .s150_p06 => [.s150_p03]
  | .s150_p07 => [.s150_p04]
  | .s150_p08 => [.s150_p03, .s150_p05]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 事業運営の不変制約。法規制・契約条件 (ord=2) -/
  | BusinessConstraint
  /-- 補充オペレーションの運用ルール。効率に応じて調整可能 (ord=1) -/
  | OperationalRule
  /-- 需要予測に関する仮説。販売データで継続的に検証 (ord=0) -/
  | DemandForecast
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .BusinessConstraint => 2
  | .OperationalRule => 1
  | .DemandForecast => 0

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
  bottom := .DemandForecast
  nontrivial := ⟨.BusinessConstraint, .DemandForecast, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- BusinessConstraint
  | .s150_p01 | .s150_p02 => .BusinessConstraint
  -- OperationalRule
  | .s150_p03 | .s150_p04 | .s150_p05 => .OperationalRule
  -- DemandForecast
  | .s150_p06 | .s150_p07 | .s150_p08 => .DemandForecast

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

end TestCoverage.S150
