/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **traveler_safety** (ord=4): 旅行者の安全・法的制約 [C1, C2]
- **external_service** (ord=3): 航空会社・ホテルAPI等への外部依存 [H1, H2]
- **preference** (ord=2): ユーザの旅行嗜好・予算設定 [C3, C4]
- **recommendation** (ord=1): AIが生成するプラン提案・最適化 [H3, H4]
-/

namespace TestCoverage.S17

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | ts1
  | ts2
  | es1
  | es2
  | pref1
  | pref2
  | pref3
  | rec1
  | rec2
  | rec3
  | rec4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .ts1 => []
  | .ts2 => []
  | .es1 => []
  | .es2 => [.ts1]
  | .pref1 => [.ts1]
  | .pref2 => [.ts2, .es1]
  | .pref3 => [.es2]
  | .rec1 => [.pref1, .es1]
  | .rec2 => [.pref2]
  | .rec3 => [.pref3, .es2]
  | .rec4 => [.rec1]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 旅行者の安全・法的制約 (ord=4) -/
  | traveler_safety
  /-- 航空会社・ホテルAPI等への外部依存 (ord=3) -/
  | external_service
  /-- ユーザの旅行嗜好・予算設定 (ord=2) -/
  | preference
  /-- AIが生成するプラン提案・最適化 (ord=1) -/
  | recommendation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .traveler_safety => 4
  | .external_service => 3
  | .preference => 2
  | .recommendation => 1

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
  bottom := .recommendation
  nontrivial := ⟨.traveler_safety, .recommendation, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- traveler_safety
  | .ts1 | .ts2 => .traveler_safety
  -- external_service
  | .es1 | .es2 => .external_service
  -- preference
  | .pref1 | .pref2 | .pref3 => .preference
  -- recommendation
  | .rec1 | .rec2 | .rec3 | .rec4 => .recommendation

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

end TestCoverage.S17
