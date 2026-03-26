/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **physics** (ord=4): 核融合の物理法則に基づく不変条件。覆すには物理学の革新が必要。 [C2, C3]
- **safety** (ord=3): 炉壁・機器保護のための安全境界。ハードウェアで強制。 [C1, C2]
- **operational** (ord=2): 物理学者チームが設定する運転パラメータ。実験ごとに変更可能。 [C4, C5]
- **control** (ord=1): AIが自律的に調整する制御戦略。物理モデルに基づく。 [H1, H2, H3]
- **hyp** (ord=0): 未検証の仮説。実験データで検証が必要。 [H4]
-/

namespace Scenario191

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | phys1
  | phys2
  | phys3
  | safe1
  | safe2
  | safe3
  | ops1
  | ops2
  | ops3
  | ctrl1
  | ctrl2
  | ctrl3
  | ctrl4
  | hyp1
  | hyp2
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .phys1 => []
  | .phys2 => []
  | .phys3 => []
  | .safe1 => [.phys1]
  | .safe2 => [.phys1, .phys2]
  | .safe3 => [.phys3]
  | .ops1 => [.safe1]
  | .ops2 => [.safe2]
  | .ops3 => [.safe1, .safe3]
  | .ctrl1 => [.safe1, .safe2, .ops1]
  | .ctrl2 => [.phys2, .ops1]
  | .ctrl3 => [.safe3, .ctrl1]
  | .ctrl4 => [.phys3, .ops3]
  | .hyp1 => [.ctrl1]
  | .hyp2 => [.ops2, .ctrl3]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 核融合の物理法則に基づく不変条件。覆すには物理学の革新が必要。 (ord=4) -/
  | physics
  /-- 炉壁・機器保護のための安全境界。ハードウェアで強制。 (ord=3) -/
  | safety
  /-- 物理学者チームが設定する運転パラメータ。実験ごとに変更可能。 (ord=2) -/
  | operational
  /-- AIが自律的に調整する制御戦略。物理モデルに基づく。 (ord=1) -/
  | control
  /-- 未検証の仮説。実験データで検証が必要。 (ord=0) -/
  | hyp
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .physics => 4
  | .safety => 3
  | .operational => 2
  | .control => 1
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
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- physics
  | .phys1 | .phys2 | .phys3 => .physics
  -- safety
  | .safe1 | .safe2 | .safe3 => .safety
  -- operational
  | .ops1 | .ops2 | .ops3 => .operational
  -- control
  | .ctrl1 | .ctrl2 | .ctrl3 | .ctrl4 => .control
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

end Scenario191
