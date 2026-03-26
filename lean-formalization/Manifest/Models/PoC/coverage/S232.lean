/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **safety** (ord=4): 利用者の身体的安全を保証する不変条件。衝突回避・緊急停止。 [C1]
- **legal** (ord=3): 道路交通法その他の法規制への準拠。外部制度で固定。 [C3]
- **autonomy** (ord=2): 利用者の自己決定権と意思の尊重。行き先・ペースの決定権。 [C2, C5]
- **navigation** (ord=1): AIが行う経路計画・障害物回避の戦略。環境に応じて動的調整。 [H1, H2]
- **hyp** (ord=0): 未検証の仮説。実地運用データで検証が必要。 [H3, H4]
-/

namespace Scenario232

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | saf1
  | saf2
  | saf3
  | leg1
  | leg2
  | aut1
  | aut2
  | aut3
  | nav1
  | nav2
  | nav3
  | nav4
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .saf1 => []
  | .saf2 => []
  | .saf3 => []
  | .leg1 => [.saf1]
  | .leg2 => [.saf2]
  | .aut1 => [.saf1, .leg1]
  | .aut2 => [.saf3]
  | .aut3 => [.leg1, .aut1]
  | .nav1 => [.saf1, .saf3, .leg1]
  | .nav2 => [.leg1, .nav1]
  | .nav3 => [.aut1, .aut2]
  | .nav4 => [.saf2, .aut3]
  | .hyp1 => [.nav3]
  | .hyp2 => [.nav1, .nav4]
  | .hyp3 => [.aut2, .nav3]
  | .hyp4 => [.saf2, .nav2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 利用者の身体的安全を保証する不変条件。衝突回避・緊急停止。 (ord=4) -/
  | safety
  /-- 道路交通法その他の法規制への準拠。外部制度で固定。 (ord=3) -/
  | legal
  /-- 利用者の自己決定権と意思の尊重。行き先・ペースの決定権。 (ord=2) -/
  | autonomy
  /-- AIが行う経路計画・障害物回避の戦略。環境に応じて動的調整。 (ord=1) -/
  | navigation
  /-- 未検証の仮説。実地運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .safety => 4
  | .legal => 3
  | .autonomy => 2
  | .navigation => 1
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
  nontrivial := ⟨.safety, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- legal
  | .leg1 | .leg2 => .legal
  -- autonomy
  | .aut1 | .aut2 | .aut3 => .autonomy
  -- navigation
  | .nav1 | .nav2 | .nav3 | .nav4 => .navigation
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 | .hyp4 => .hyp

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

end Scenario232
