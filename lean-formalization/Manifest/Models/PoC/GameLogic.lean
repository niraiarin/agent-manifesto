/-!
# 条件付き公理体系（スタンドアロン生成）

このファイルは generate-conditional-axiom-system.sh によって
ModelSpec JSON から自動生成されました。独自の PropositionId を含みます。

手動で編集しないでください。

## 層構造

- **AntiCheat** (ord=4): 不正防止の不変条件。サーバー権威モデル [C1]
- **PhysicsRule** (ord=3): 物理法則。ゲーム世界の基本制約 [C2, H1]
- **BalanceParam** (ord=2): バランスパラメータ。パッチで調整可能 [C3, H2]
- **AIBehavior** (ord=1): NPC AI の振る舞い。学習ベースで自動調整 [H3, H4]
-/

namespace GameLogic

-- ============================================================
-- 0. PropositionId (プロジェクト固有)
-- ============================================================

/-- プロジェクト固有の命題識別子。 -/
inductive PropositionId where
  | gl_p01
  | gl_p02
  | gl_p03
  | gl_p04
  | gl_p05
  | gl_p06
  | gl_p07
  | gl_p08
  | gl_p09
  | gl_p10
  deriving BEq, Repr, DecidableEq

/-- 命題の直接依存先。 -/
def PropositionId.dependencies : PropositionId → List PropositionId
  | .gl_p01 => []
  | .gl_p02 => []
  | .gl_p03 => [.gl_p01]
  | .gl_p04 => [.gl_p02]
  | .gl_p05 => [.gl_p01, .gl_p02]
  | .gl_p06 => [.gl_p03]
  | .gl_p07 => [.gl_p04]
  | .gl_p08 => [.gl_p03, .gl_p05]
  | .gl_p09 => [.gl_p06]
  | .gl_p10 => [.gl_p07, .gl_p08]

/-- 命題が別の命題に直接依存する。 -/
def propositionDependsOn (a b : PropositionId) : Bool :=
  a.dependencies.contains b

-- ============================================================
-- 1. ConcreteLayer inductive
-- ============================================================

/-- 認識論的層。 -/
inductive ConcreteLayer where
  /-- 不正防止の不変条件。サーバー権威モデル (ord=4) -/
  | AntiCheat
  /-- 物理法則。ゲーム世界の基本制約 (ord=3) -/
  | PhysicsRule
  /-- バランスパラメータ。パッチで調整可能 (ord=2) -/
  | BalanceParam
  /-- NPC AI の振る舞い。学習ベースで自動調整 (ord=1) -/
  | AIBehavior
  deriving BEq, Repr, DecidableEq

-- ============================================================
-- 2. EpistemicLayerClass instance
-- ============================================================

/-- ConcreteLayer の順序値。 -/
def ConcreteLayer.ord : ConcreteLayer → Nat
  | .AntiCheat => 4
  | .PhysicsRule => 3
  | .BalanceParam => 2
  | .AIBehavior => 1

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
  bottom := .AIBehavior
  nontrivial := ⟨.AntiCheat, .AIBehavior, by simp [ConcreteLayer.ord]⟩
  ord_injective := by
    intro a b; cases a <;> cases b <;> simp [ConcreteLayer.ord]
  ord_bounded := ⟨4, fun a => by cases a <;> simp [ConcreteLayer.ord]⟩
  bottom_minimum := fun a => by cases a <;> simp [ConcreteLayer.ord]

-- ============================================================
-- 3. classify
-- ============================================================

/-- 全命題の層分類。 -/
def classify : PropositionId → ConcreteLayer
  -- AntiCheat
  | .gl_p01 | .gl_p02 => .AntiCheat
  -- PhysicsRule
  | .gl_p03 | .gl_p04 | .gl_p05 => .PhysicsRule
  -- BalanceParam
  | .gl_p06 | .gl_p07 | .gl_p08 => .BalanceParam
  -- AIBehavior
  | .gl_p09 | .gl_p10 => .AIBehavior

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

end GameLogic
