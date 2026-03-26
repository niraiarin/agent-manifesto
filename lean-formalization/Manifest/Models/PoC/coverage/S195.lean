/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **lifeCritical** (ord=5): クルーの生命に直結する不変条件。違反はミッション中止。 [C1, C5]
- **physics** (ord=4): 宇宙環境の物理的制約。変更不可能。 [C2, C6]
- **logistics** (ord=3): 補給・在庫に関するリソース制約。補給サイクルに依存。 [C3]
- **operations** (ord=2): 地上管制が設定する運用方針。ミッションフェーズで変動。 [C4]
- **optimization** (ord=1): AIが自律的に調整する最適化戦略。 [H1, H2, H3]
- **hypothesis** (ord=0): 運用データで検証が必要な仮説。 [H4]
-/

namespace Scenario195

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | life1
  | life2
  | life3
  | phy1
  | phy2
  | log1
  | log2
  | opr1
  | opr2
  | opr3
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | hyp1
  | hyp2
  | hyp3
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .life1 => []
  | .life2 => []
  | .life3 => [.life1]
  | .phy1 => []
  | .phy2 => []
  | .log1 => [.life2]
  | .log2 => [.phy2]
  | .opr1 => [.life1, .phy1]
  | .opr2 => [.log1, .log2]
  | .opr3 => [.life3, .phy1]
  | .opt1 => [.life2, .life3]
  | .opt2 => [.log1, .log2, .phy2]
  | .opt3 => [.life1, .opr1]
  | .opt4 => [.opt1, .opt2]
  | .opt5 => [.opr2, .opt3]
  | .hyp1 => [.phy1, .opr1]
  | .hyp2 => [.opt3, .opt4]
  | .hyp3 => [.opr3, .opt5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- クルーの生命に直結する不変条件。違反はミッション中止。 (ord=5) -/
  | lifeCritical
  /-- 宇宙環境の物理的制約。変更不可能。 (ord=4) -/
  | physics
  /-- 補給・在庫に関するリソース制約。補給サイクルに依存。 (ord=3) -/
  | logistics
  /-- 地上管制が設定する運用方針。ミッションフェーズで変動。 (ord=2) -/
  | operations
  /-- AIが自律的に調整する最適化戦略。 (ord=1) -/
  | optimization
  /-- 運用データで検証が必要な仮説。 (ord=0) -/
  | hypothesis
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .lifeCritical => 5
  | .physics => 4
  | .logistics => 3
  | .operations => 2
  | .optimization => 1
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
  nontrivial := ⟨.lifeCritical, .hypothesis, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- lifeCritical
  | .life1 | .life2 | .life3 => .lifeCritical
  -- physics
  | .phy1 | .phy2 => .physics
  -- logistics
  | .log1 | .log2 => .logistics
  -- operations
  | .opr1 | .opr2 | .opr3 => .operations
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
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

end Scenario195
