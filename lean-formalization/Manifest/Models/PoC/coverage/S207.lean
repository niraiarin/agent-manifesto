/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ecology** (ord=5): 生態学的基本法則・保全制約 [C1, H1]
- **geography** (ord=4): 地理・地形的制約 [H2, H3]
- **climate** (ord=3): 気象・気候の外部依存 [H4, H5]
- **migration** (ord=2): 渡り経路予測モデル [C2, H6]
- **alert** (ord=1): 警報・通知ポリシー [C3, H7]
- **hypothesis** (ord=0): 未検証の仮説 [H8]
-/

namespace BirdMigrationPrediction

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | eco1
  | eco2
  | geo1
  | geo2
  | clm1
  | clm2
  | clm3
  | route1
  | route2
  | alt1
  | alt2
  | hyp1
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .eco1 => []
  | .eco2 => []
  | .geo1 => []
  | .geo2 => [.eco1]
  | .clm1 => []
  | .clm2 => [.geo1]
  | .clm3 => []
  | .route1 => [.eco1, .geo2, .clm1]
  | .route2 => [.clm3]
  | .alt1 => [.route1]
  | .alt2 => [.route1, .clm2]
  | .hyp1 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 生態学的基本法則・保全制約 (ord=5) -/
  | ecology
  /-- 地理・地形的制約 (ord=4) -/
  | geography
  /-- 気象・気候の外部依存 (ord=3) -/
  | climate
  /-- 渡り経路予測モデル (ord=2) -/
  | migration
  /-- 警報・通知ポリシー (ord=1) -/
  | alert
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ecology => 5
  | .geography => 4
  | .climate => 3
  | .migration => 2
  | .alert => 1
  | .hypothesis => 0

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
  bottom := .hypothesis
  nontrivial := ⟨.ecology, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ecology
  | .eco1 | .eco2 => .ecology
  -- geography
  | .geo1 | .geo2 => .geography
  -- climate
  | .clm1 | .clm2 | .clm3 => .climate
  -- migration
  | .route1 | .route2 => .migration
  -- alert
  | .alt1 | .alt2 => .alert
  -- hypothesis
  | .hyp1 => .hypothesis

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

end BirdMigrationPrediction
