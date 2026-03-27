/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physical** (ord=6): クレーンの物理的制約。荷重・構造限界で不変。 [C2]
- **safety** (ord=5): 安全規制による制約。法規で強制。 [C1, C2]
- **environmental** (ord=4): 気象・環境条件。自然法則で決定。 [C6]
- **external** (ord=3): 外部スケジュールへの依存。自律制御できない。 [C3]
- **governance** (ord=2): 運用統治ルール。管理方針で変更可能。 [C4, C5]
- **optimization** (ord=1): 最適化アルゴリズムの設計方針。技術で変更可能。 [H1, H2, H3, H4]
- **hyp** (ord=0): 未検証の仮説。実運用データで検証が必要。 [H4]
-/

namespace Scenario217

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phy1
  | phy2
  | saf1
  | saf2
  | saf3
  | env1
  | env2
  | ext1
  | ext2
  | ext3
  | gov1
  | gov2
  | gov3
  | gov4
  | opt1
  | opt2
  | opt3
  | opt4
  | opt5
  | opt6
  | opt7
  | hyp1
  | hyp2
  | hyp3
  | hyp4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phy1 => []
  | .phy2 => []
  | .saf1 => [.phy1]
  | .saf2 => [.phy1, .phy2]
  | .saf3 => [.phy2]
  | .env1 => [.saf1]
  | .env2 => [.saf2]
  | .ext1 => [.env1]
  | .ext2 => [.saf3]
  | .ext3 => [.env2]
  | .gov1 => [.saf1, .saf2]
  | .gov2 => [.ext1]
  | .gov3 => [.ext1, .ext2]
  | .gov4 => [.ext3]
  | .opt1 => [.saf1, .saf2, .gov1]
  | .opt2 => [.ext1, .gov2]
  | .opt3 => [.gov1, .gov3]
  | .opt4 => [.env1, .env2, .gov4]
  | .opt5 => [.saf3, .ext2, .gov3]
  | .opt6 => [.env2, .ext3]
  | .opt7 => [.gov1, .opt1]
  | .hyp1 => [.opt4, .opt6]
  | .hyp2 => [.opt2, .opt5]
  | .hyp3 => [.opt3]
  | .hyp4 => [.opt7]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- クレーンの物理的制約。荷重・構造限界で不変。 (ord=6) -/
  | physical
  /-- 安全規制による制約。法規で強制。 (ord=5) -/
  | safety
  /-- 気象・環境条件。自然法則で決定。 (ord=4) -/
  | environmental
  /-- 外部スケジュールへの依存。自律制御できない。 (ord=3) -/
  | external
  /-- 運用統治ルール。管理方針で変更可能。 (ord=2) -/
  | governance
  /-- 最適化アルゴリズムの設計方針。技術で変更可能。 (ord=1) -/
  | optimization
  /-- 未検証の仮説。実運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physical => 6
  | .safety => 5
  | .environmental => 4
  | .external => 3
  | .governance => 2
  | .optimization => 1
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
  nontrivial := ⟨.physical, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨6, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physical
  | .phy1 | .phy2 => .physical
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- environmental
  | .env1 | .env2 => .environmental
  -- external
  | .ext1 | .ext2 | .ext3 => .external
  -- governance
  | .gov1 | .gov2 | .gov3 | .gov4 => .governance
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 | .opt6 | .opt7 => .optimization
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

end Scenario217
