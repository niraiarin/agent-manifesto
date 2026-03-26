/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **geological** (ord=3): 地質学的不変条件。帯水層の物理特性と地下水力学。 [C1]
- **regulatory** (ord=2): ISO品質基準、環境保全義務、既存構造物保護。 [C2, C3, C4]
- **exploration** (ord=1): AIによる探査データ解析と候補地点推定の戦略。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の地球物理学的仮説。フィールドデータで検証が必要。 [H1, H2]
-/

namespace Scenario239

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | geol1
  | geol2
  | regu1
  | regu2
  | regu3
  | expl1
  | expl2
  | expl3
  | expl4
  | expl5
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .geol1 => []
  | .geol2 => []
  | .regu1 => [.geol1]
  | .regu2 => [.geol1, .geol2]
  | .regu3 => [.geol2]
  | .expl1 => [.geol1, .regu2]
  | .expl2 => [.regu1, .regu2]
  | .expl3 => [.regu3]
  | .expl4 => [.expl1, .expl2]
  | .expl5 => [.regu1, .expl3]
  | .hyp1 => [.expl1]
  | .hyp2 => [.expl4, .expl5]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 地質学的不変条件。帯水層の物理特性と地下水力学。 (ord=3) -/
  | geological
  /-- ISO品質基準、環境保全義務、既存構造物保護。 (ord=2) -/
  | regulatory
  /-- AIによる探査データ解析と候補地点推定の戦略。 (ord=1) -/
  | exploration
  /-- 未検証の地球物理学的仮説。フィールドデータで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .geological => 3
  | .regulatory => 2
  | .exploration => 1
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
  nontrivial := ⟨.geological, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- geological
  | .geol1 | .geol2 => .geological
  -- regulatory
  | .regu1 | .regu2 | .regu3 => .regulatory
  -- exploration
  | .expl1 | .expl2 | .expl3 | .expl4 | .expl5 => .exploration
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

end Scenario239
