/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **compliance** (ord=3): 法規制と顧客契約。労基法・交通法規。不可侵。 [C2, C4]
- **customer** (ord=2): 顧客との合意事項。時間帯指定・置き配承認。 [C1, C3]
- **routing** (ord=1): AIの配送最適化手法。改善可能。 [H1, H2, H3]
- **hyp** (ord=0): 検証待ちの仮説。配送データで確認。 [H3]
-/

namespace Scenario280

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | cmp1
  | cmp2
  | cmp3
  | cus1
  | cus2
  | cus3
  | rte1
  | rte2
  | rte3
  | rte4
  | rte5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .cmp1 => []
  | .cmp2 => []
  | .cmp3 => []
  | .cus1 => [.cmp2]
  | .cus2 => [.cmp1]
  | .cus3 => [.cus1, .cus2]
  | .rte1 => [.cmp2, .cus1]
  | .rte2 => [.cus2, .cus3]
  | .rte3 => [.cmp1, .cmp3]
  | .rte4 => [.rte1, .rte2]
  | .rte5 => [.rte1, .rte3]
  | .hyp1 => [.rte3, .rte4]
  | .hyp2 => [.rte5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 法規制と顧客契約。労基法・交通法規。不可侵。 (ord=3) -/
  | compliance
  /-- 顧客との合意事項。時間帯指定・置き配承認。 (ord=2) -/
  | customer
  /-- AIの配送最適化手法。改善可能。 (ord=1) -/
  | routing
  /-- 検証待ちの仮説。配送データで確認。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .compliance => 3
  | .customer => 2
  | .routing => 1
  | .hyp => 0

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
  bottom := .hyp
  nontrivial := ⟨.compliance, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- compliance
  | .cmp1 | .cmp2 | .cmp3 => .compliance
  -- customer
  | .cus1 | .cus2 | .cus3 => .customer
  -- routing
  | .rte1 | .rte2 | .rte3 | .rte4 | .rte5 => .routing
  -- hyp
  | .hyp1 | .hyp2 => .hyp

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

end Scenario280
