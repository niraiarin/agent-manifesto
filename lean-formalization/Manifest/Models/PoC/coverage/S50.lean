/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **brand_ethics** (ord=4): ボディポジティブ・多様性配慮・著作権など倫理的・法的制約 [C1, C2]
- **fashion_knowledge** (ord=3): 色彩理論・体型別スタイリング・トレンド分析の経験的前提 [C3, H1]
- **styling_policy** (ord=2): 提案ロジック・パーソナライズ方針・在庫連携ルール [C4, H2, H3]
- **display_parameter** (ord=1): 提案表示数・画像サイズ・ソート順などのUIパラメータ [C5, H4]
-/

namespace Manifest.Models

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | t1
  | t4
  | t6
  | e1
  | e2
  | p1
  | p2
  | p5
  | l1
  | d1
  | d8
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .t1 => []
  | .t4 => []
  | .t6 => []
  | .e1 => []
  | .e2 => []
  | .p1 => []
  | .p2 => []
  | .p5 => []
  | .l1 => []
  | .d1 => []
  | .d8 => []

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- ボディポジティブ・多様性配慮・著作権など倫理的・法的制約 (ord=4) -/
  | brand_ethics
  /-- 色彩理論・体型別スタイリング・トレンド分析の経験的前提 (ord=3) -/
  | fashion_knowledge
  /-- 提案ロジック・パーソナライズ方針・在庫連携ルール (ord=2) -/
  | styling_policy
  /-- 提案表示数・画像サイズ・ソート順などのUIパラメータ (ord=1) -/
  | display_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .brand_ethics => 4
  | .fashion_knowledge => 3
  | .styling_policy => 2
  | .display_parameter => 1

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
  bottom := .display_parameter
  nontrivial := ⟨.brand_ethics, .display_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- brand_ethics
  | .t1 | .t4 | .t6 => .brand_ethics
  -- fashion_knowledge
  | .e1 | .e2 | .p1 => .fashion_knowledge
  -- styling_policy
  | .p2 | .p5 | .l1 => .styling_policy
  -- display_parameter
  | .d1 | .d8 => .display_parameter

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

end Manifest.Models
