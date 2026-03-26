/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=3): 食品衛生法・HACCP基準に基づく温度管理の絶対条件 [C1, C2, C3]
- **environment** (ord=2): 外気温・設備性能等の外部依存前提 [H1, H2, H5]
- **policy** (ord=1): 倉庫管理者が設定する運用方針 [C4, C5, H3]
- **hypothesis** (ord=0): 未検証の省エネ・予測制御仮説 [H4, H6, H7]
-/

namespace WarehouseTemp

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
  | env1
  | env2
  | env3
  | pol1
  | pol2
  | pol3
  | pol4
  | pol5
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  | hyp5
  | hyp6
  | hyp7
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => []
  | .env1 => []
  | .env2 => []
  | .env3 => [.safe1]
  | .pol1 => [.safe1, .safe2]
  | .pol2 => [.safe3, .env1]
  | .pol3 => [.env2]
  | .pol4 => [.env3]
  | .pol5 => [.safe2, .env1, .env2]
  | .hyp1 => [.env1, .pol1]
  | .hyp2 => [.pol2, .pol3]
  | .hyp3 => [.pol4, .pol5]
  | .hyp4 => [.hyp1, .hyp2]
  | .hyp5 => [.hyp1]
  | .hyp6 => [.hyp3, .hyp4]
  | .hyp7 => [.hyp5, .hyp6]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 食品衛生法・HACCP基準に基づく温度管理の絶対条件 (ord=3) -/
  | constraint
  /-- 外気温・設備性能等の外部依存前提 (ord=2) -/
  | environment
  /-- 倉庫管理者が設定する運用方針 (ord=1) -/
  | policy
  /-- 未検証の省エネ・予測制御仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 3
  | .environment => 2
  | .policy => 1
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
  nontrivial := ⟨.constraint, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .safe1 | .safe2 | .safe3 => .constraint
  -- environment
  | .env1 | .env2 | .env3 => .environment
  -- policy
  | .pol1 | .pol2 | .pol3 | .pol4 | .pol5 => .policy
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 | .hyp5 | .hyp6 | .hyp7 => .hypothesis

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

end WarehouseTemp
