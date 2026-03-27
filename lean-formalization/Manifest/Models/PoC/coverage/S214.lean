/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=5): 地質学・水文学の物理法則。覆すには科学的発見が必要。 [C3]
- **safety** (ord=4): 人命に関わる安全要件。見逃し禁止。 [C2, C3]
- **governance** (ord=3): 行政の意思決定権限。法的枠組みで固定。 [C1, C5]
- **external** (ord=2): 外部データソースへの依存。自律制御できない。 [C4]
- **prediction** (ord=1): 予測アルゴリズムの設計方針。技術進歩で変更可能。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実地データで検証が必要。 [H4]
-/

namespace Scenario214

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
  | gov1
  | gov2
  | gov3
  | ext1
  | ext2
  | ext3
  | pred1
  | pred2
  | pred3
  | pred4
  | pred5
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
  | .gov1 => [.saf1]
  | .gov2 => [.saf1, .saf2]
  | .gov3 => [.saf3]
  | .ext1 => [.gov1]
  | .ext2 => [.saf2]
  | .ext3 => [.gov2]
  | .pred1 => [.saf2, .ext1, .ext2]
  | .pred2 => [.gov2, .ext3]
  | .pred3 => [.ext1, .ext2]
  | .pred4 => [.gov3, .pred1]
  | .pred5 => [.ext2, .pred3]
  | .hyp1 => [.pred1, .pred2]
  | .hyp2 => [.gov1, .pred4]
  | .hyp3 => [.pred5]
  | .hyp4 => [.pred3, .pred4]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地質学・水文学の物理法則。覆すには科学的発見が必要。 (ord=5) -/
  | physics
  /-- 人命に関わる安全要件。見逃し禁止。 (ord=4) -/
  | safety
  /-- 行政の意思決定権限。法的枠組みで固定。 (ord=3) -/
  | governance
  /-- 外部データソースへの依存。自律制御できない。 (ord=2) -/
  | external
  /-- 予測アルゴリズムの設計方針。技術進歩で変更可能。 (ord=1) -/
  | prediction
  /-- 未検証の仮説。実地データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 5
  | .safety => 4
  | .governance => 3
  | .external => 2
  | .prediction => 1
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
  nontrivial := ⟨.physics, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨5, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phy1 | .phy2 => .physics
  -- safety
  | .saf1 | .saf2 | .saf3 => .safety
  -- governance
  | .gov1 | .gov2 | .gov3 => .governance
  -- external
  | .ext1 | .ext2 | .ext3 => .external
  -- prediction
  | .pred1 | .pred2 | .pred3 | .pred4 | .pred5 => .prediction
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

end Scenario214
