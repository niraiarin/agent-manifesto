/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=4): 絶対不変条件。違反でシステム停止 [C2, C5]
- **environment** (ord=3): 外部依存。自分で制御できない前提 [H1, H5, H8]
- **policy** (ord=2): 人間が設定・調整する運用方針 [C1, C3]
- **strategy** (ord=1): AIが自律的に最適化する戦略 [C3, C6]
- **hypothesis** (ord=0): 未検証の仮説 [H4]
-/

namespace StockTrading

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
  | str1
  | str2
  | str3
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .safe1 => []
  | .safe2 => []
  | .safe3 => []
  | .env1 => []
  | .env2 => []
  | .env3 => []
  | .pol1 => [.safe3]
  | .pol2 => [.safe1]
  | .pol3 => [.safe2, .env1]
  | .pol4 => []
  | .str1 => [.safe1, .pol4]
  | .str2 => [.str1]
  | .str3 => [.env1, .env3]
  | .hyp2 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 絶対不変条件。違反でシステム停止 (ord=4) -/
  | constraint
  /-- 外部依存。自分で制御できない前提 (ord=3) -/
  | environment
  /-- 人間が設定・調整する運用方針 (ord=2) -/
  | policy
  /-- AIが自律的に最適化する戦略 (ord=1) -/
  | strategy
  /-- 未検証の仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 4
  | .environment => 3
  | .policy => 2
  | .strategy => 1
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
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
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
  | .pol1 | .pol2 | .pol3 | .pol4 => .policy
  -- strategy
  | .str1 | .str2 | .str3 => .strategy
  -- hypothesis
  | .hyp2 => .hypothesis

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

end StockTrading
