/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **environmental** (ord=4): 海洋環境の物理的制約と法的規制。行政が設定。 [C1, C2]
- **regulatory** (ord=3): 食品安全と公益に関する法的要件。 [C4]
- **operational** (ord=2): 施設管理者の運用方針と電力需要。 [C3, C5]
- **optimization** (ord=1): AI最適化アルゴリズムの設計判断。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。運用データで検証が必要。 [H4]
-/

namespace Scenario287

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | env1
  | env2
  | env3
  | rgl1
  | rgl2
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
  | .env1 => []
  | .env2 => []
  | .env3 => []
  | .rgl1 => [.env1]
  | .rgl2 => [.env2, .env3]
  | .opr1 => [.env1]
  | .opr2 => [.rgl1, .rgl2]
  | .opr3 => [.opr1, .opr2]
  | .opt1 => [.env2, .rgl1]
  | .opt2 => [.env2, .opr1]
  | .opt3 => [.rgl2, .opr2]
  | .opt4 => [.opt1, .opt3]
  | .opt5 => [.opr3, .opt2]
  | .hyp1 => [.env3, .opt4]
  | .hyp2 => [.opt5]
  | .hyp3 => [.hyp1, .hyp2]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 海洋環境の物理的制約と法的規制。行政が設定。 (ord=4) -/
  | environmental
  /-- 食品安全と公益に関する法的要件。 (ord=3) -/
  | regulatory
  /-- 施設管理者の運用方針と電力需要。 (ord=2) -/
  | operational
  /-- AI最適化アルゴリズムの設計判断。 (ord=1) -/
  | optimization
  /-- 未検証の仮説。運用データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .environmental => 4
  | .regulatory => 3
  | .operational => 2
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
  nontrivial := ⟨.environmental, .hyp, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- environmental
  | .env1 | .env2 | .env3 => .environmental
  -- regulatory
  | .rgl1 | .rgl2 => .regulatory
  -- operational
  | .opr1 | .opr2 | .opr3 => .operational
  -- optimization
  | .opt1 | .opt2 | .opt3 | .opt4 | .opt5 => .optimization
  -- hyp
  | .hyp1 | .hyp2 | .hyp3 => .hyp

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

end Scenario287
