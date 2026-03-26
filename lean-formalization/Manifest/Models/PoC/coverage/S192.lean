/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **ethics** (ord=3): 利用者の権利と尊厳に関わる不可侵の原則。 [C1, C3]
- **accessibility** (ord=2): 障害特性に応じたアクセシビリティ要件。利用者に依存。 [C2, C4]
- **adaptation** (ord=1): 個別適応のための設計判断。運用を通じて調整可能。 [C2, H1, H2]
- **hypothesis** (ord=0): 未検証の仮説。利用者テストで検証が必要。 [H3]
-/

namespace Scenario192

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | eth1
  | eth2
  | eth3
  | acc1
  | acc2
  | acc3
  | adp1
  | adp2
  | adp3
  | adp4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .eth1 => []
  | .eth2 => []
  | .eth3 => []
  | .acc1 => [.eth1]
  | .acc2 => [.eth2]
  | .acc3 => [.eth1, .eth3]
  | .adp1 => [.acc1, .acc3]
  | .adp2 => [.eth2, .acc2]
  | .adp3 => [.acc1]
  | .adp4 => [.adp2, .adp3]
  | .hyp1 => [.adp1]
  | .hyp2 => [.adp1, .adp4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 利用者の権利と尊厳に関わる不可侵の原則。 (ord=3) -/
  | ethics
  /-- 障害特性に応じたアクセシビリティ要件。利用者に依存。 (ord=2) -/
  | accessibility
  /-- 個別適応のための設計判断。運用を通じて調整可能。 (ord=1) -/
  | adaptation
  /-- 未検証の仮説。利用者テストで検証が必要。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .ethics => 3
  | .accessibility => 2
  | .adaptation => 1
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
  nontrivial := ⟨.ethics, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- ethics
  | .eth1 | .eth2 | .eth3 => .ethics
  -- accessibility
  | .acc1 | .acc2 | .acc3 => .accessibility
  -- adaptation
  | .adp1 | .adp2 | .adp3 | .adp4 => .adaptation
  -- hypothesis
  | .hyp1 | .hyp2 => .hypothesis

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

end Scenario192
