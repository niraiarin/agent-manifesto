/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **lifeSafety** (ord=3): 人命に直結する不変条件 [C1, C2, C3]
- **dataSource** (ord=2): 観測・データに関する外部依存 [C4, C6, H1]
- **prediction** (ord=1): 予測モデル・アルゴリズムの方針 [C5, H2, H3, H5]
- **adaptation** (ord=0): 環境変化への適応戦略 [H4, H6]
-/

namespace FloodWarning

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | life1
  | life2
  | life3
  | data1
  | data2
  | data3
  | data4
  | pred1
  | pred2
  | pred3
  | pred4
  | adap1
  | adap2
  | adap3
  | adap4
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .life1 => []
  | .life2 => []
  | .life3 => [.life1]
  | .data1 => [.life1]
  | .data2 => []
  | .data3 => [.life3]
  | .data4 => [.life1]
  | .pred1 => [.data1, .data2]
  | .pred2 => [.life1, .data1]
  | .pred3 => [.data1, .data3]
  | .pred4 => [.life2]
  | .adap1 => [.pred1, .data2]
  | .adap2 => [.data4, .pred3]
  | .adap3 => [.pred1]
  | .adap4 => [.pred2, .life3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 人命に直結する不変条件 (ord=3) -/
  | lifeSafety
  /-- 観測・データに関する外部依存 (ord=2) -/
  | dataSource
  /-- 予測モデル・アルゴリズムの方針 (ord=1) -/
  | prediction
  /-- 環境変化への適応戦略 (ord=0) -/
  | adaptation
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .lifeSafety => 3
  | .dataSource => 2
  | .prediction => 1
  | .adaptation => 0

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
  bottom := .adaptation
  nontrivial := ⟨.lifeSafety, .adaptation, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨3, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- lifeSafety
  | .life1 | .life2 | .life3 => .lifeSafety
  -- dataSource
  | .data1 | .data2 | .data3 | .data4 => .dataSource
  -- prediction
  | .pred1 | .pred2 | .pred3 | .pred4 => .prediction
  -- adaptation
  | .adap1 | .adap2 | .adap3 | .adap4 => .adaptation

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

end FloodWarning
