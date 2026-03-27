/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environment** (ord=4): 深海環境の物理的制約。人間が変更できない。 [C1, C4]
- **regulation** (ord=3): 環境保護と安全に関する規制的制約。 [C2, C5]
- **mission** (ord=2): オペレーターが設定するミッションパラメータ。 [C3, C6]
- **autonomy** (ord=1): ロボットが自律的に最適化する行動戦略。 [H1, H2, H3]
- **hypothesis** (ord=0): 運用データで検証が必要な仮説。 [H4]
-/

namespace Scenario193

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | env1
  | env2
  | reg1
  | reg2
  | reg3
  | mis1
  | mis2
  | mis3
  | aut1
  | aut2
  | aut3
  | aut4
  | aut5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .env1 => []
  | .env2 => []
  | .reg1 => []
  | .reg2 => []
  | .reg3 => [.reg1]
  | .mis1 => [.reg2]
  | .mis2 => [.reg1]
  | .mis3 => [.mis1, .mis2]
  | .aut1 => [.env1, .reg3]
  | .aut2 => [.reg2, .reg3]
  | .aut3 => [.env2, .mis1]
  | .aut4 => [.env1, .env2, .aut1]
  | .aut5 => [.mis3, .aut2]
  | .hyp1 => [.mis2]
  | .hyp2 => [.aut5, .hyp1]
  | .hyp3 => [.aut1, .aut3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 深海環境の物理的制約。人間が変更できない。 (ord=4) -/
  | environment
  /-- 環境保護と安全に関する規制的制約。 (ord=3) -/
  | regulation
  /-- オペレーターが設定するミッションパラメータ。 (ord=2) -/
  | mission
  /-- ロボットが自律的に最適化する行動戦略。 (ord=1) -/
  | autonomy
  /-- 運用データで検証が必要な仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environment => 4
  | .regulation => 3
  | .mission => 2
  | .autonomy => 1
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
  nontrivial := ⟨.environment, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environment
  | .env1 | .env2 => .environment
  -- regulation
  | .reg1 | .reg2 | .reg3 => .regulation
  -- mission
  | .mis1 | .mis2 | .mis3 => .mission
  -- autonomy
  | .aut1 | .aut2 | .aut3 | .aut4 | .aut5 => .autonomy
  -- hypothesis
  | .hyp1 | .hyp2 | .hyp3 => .hypothesis

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

end Scenario193
