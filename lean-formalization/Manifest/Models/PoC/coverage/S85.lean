/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **constraint** (ord=2): 著作権法・引用ルールに基づく不変条件 [C1, C2, C3]
- **policy** (ord=1): プラットフォーム・配信者が設定する要約方針 [C4, H1, H2, H3]
- **hypothesis** (ord=0): 未検証の要約品質・ユーザー体験仮説 [H4, H5, H6]
-/

namespace PodcastSummary

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | safe1
  | safe2
  | safe3
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
  | .pol1 => [.safe1]
  | .pol2 => [.safe2]
  | .pol3 => [.safe3]
  | .pol4 => [.safe1, .safe2]
  | .pol5 => [.safe3]
  | .hyp1 => [.pol1, .pol2]
  | .hyp2 => [.pol3, .pol4]
  | .hyp3 => [.pol5]
  | .hyp4 => [.hyp1, .hyp2]
  | .hyp5 => [.hyp1, .hyp3]
  | .hyp6 => [.hyp4]
  | .hyp7 => [.hyp5, .hyp6]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 著作権法・引用ルールに基づく不変条件 (ord=2) -/
  | constraint
  /-- プラットフォーム・配信者が設定する要約方針 (ord=1) -/
  | policy
  /-- 未検証の要約品質・ユーザー体験仮説 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .constraint => 2
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
  ord_bounded := ⟨2, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- constraint
  | .safe1 | .safe2 | .safe3 => .constraint
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

end PodcastSummary
