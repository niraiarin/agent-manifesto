/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **brand_identity** (ord=4): ブランドガイドライン・禁止表現・法的コンプライアンスなど不変の制約 [C1, C2]
- **customer_model** (ord=3): 顧客セグメント・購買行動パターンに関する経験的仮定 [C3, H1]
- **conversation_policy** (ord=2): 応答トーン・エスカレーション基準・提案範囲の方針 [C4, H2, H3]
- **response_parameter** (ord=1): 応答速度・テンプレート選択・A/Bテスト設定 [C5, H4]
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
  | l1
  | l2
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
  | .l1 => []
  | .l2 => []
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
  /-- ブランドガイドライン・禁止表現・法的コンプライアンスなど不変の制約 (ord=4) -/
  | brand_identity
  /-- 顧客セグメント・購買行動パターンに関する経験的仮定 (ord=3) -/
  | customer_model
  /-- 応答トーン・エスカレーション基準・提案範囲の方針 (ord=2) -/
  | conversation_policy
  /-- 応答速度・テンプレート選択・A/Bテスト設定 (ord=1) -/
  | response_parameter
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .brand_identity => 4
  | .customer_model => 3
  | .conversation_policy => 2
  | .response_parameter => 1

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
  bottom := .response_parameter
  nontrivial := ⟨.brand_identity, .response_parameter, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- brand_identity
  | .t1 | .t4 | .t6 => .brand_identity
  -- customer_model
  | .e1 | .e2 | .p1 => .customer_model
  -- conversation_policy
  | .p2 | .l1 | .l2 => .conversation_policy
  -- response_parameter
  | .d1 | .d8 => .response_parameter

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
